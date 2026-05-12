-- ClubManager Sport
-- Attendance hardening
-- Version: 20260511000610

create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  athlete_profile_id uuid not null references public.athlete_profiles(id) on delete cascade,
  status text not null default 'unknown',
  notes text,
  recorded_by uuid references auth.users(id) on delete set null,
  recorded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.attendance
add column if not exists notes text;

alter table public.attendance
add column if not exists recorded_by uuid references auth.users(id) on delete set null;

alter table public.attendance
add column if not exists recorded_at timestamptz;

alter table public.attendance
add column if not exists created_at timestamptz not null default now();

alter table public.attendance
add column if not exists updated_at timestamptz not null default now();

do $$
declare
  status_type regtype;
begin
  select atttypid::regtype
  into status_type
  from pg_attribute
  where attrelid = 'public.attendance'::regclass
    and attname = 'status'
    and not attisdropped;

  if status_type = 'public.attendance_status'::regtype then
    execute 'alter table public.attendance alter column status set default ''unknown''::public.attendance_status';
  else
    execute 'alter table public.attendance alter column status set default ''unknown''';
  end if;
end $$;

alter table public.attendance
drop constraint if exists attendance_status_check;

alter table public.attendance
add constraint attendance_status_check
check (
  status::text in (
    'unknown',
    'present',
    'absent',
    'late',
    'excused'
  )
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'attendance_event_athlete_unique'
  ) then
    alter table public.attendance
    add constraint attendance_event_athlete_unique
    unique (event_id, athlete_profile_id);
  end if;
end $$;

alter table public.attendance enable row level security;

drop trigger if exists attendance_set_updated_at on public.attendance;

create trigger attendance_set_updated_at
before update on public.attendance
for each row
execute function public.set_updated_at();

create or replace function public.can_manage_attendance(p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.events e
    join public.club_memberships cm
      on cm.club_id = e.club_id
    where e.id = p_event_id
      and e.deleted_at is null
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('owner', 'admin', 'team_manager', 'coach', 'staff')
  );
$$;

create or replace function public.can_view_attendance(
  p_event_id uuid,
  p_athlete_profile_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.events e
    join public.club_memberships cm
      on cm.club_id = e.club_id
    where e.id = p_event_id
      and e.deleted_at is null
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  )
  or exists (
    select 1
    from public.parent_athlete_relations par
    where par.athlete_profile_id = p_athlete_profile_id
      and par.parent_user_id = auth.uid()
  )
  or exists (
    select 1
    from public.athlete_profiles ap
    where ap.id = p_athlete_profile_id
      and ap.user_id = auth.uid()
  );
$$;

create or replace function public.is_valid_attendance_row(
  p_event_id uuid,
  p_athlete_profile_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.events e
    join public.athlete_profiles ap
      on ap.club_id = e.club_id
    where e.id = p_event_id
      and ap.id = p_athlete_profile_id
      and e.deleted_at is null
      and ap.deleted_at is null
      and ap.active = true
      and (
        e.team_id is null
        or ap.team_id = e.team_id
        or exists (
          select 1
          from public.team_memberships tm
          where tm.team_id = e.team_id
            and tm.athlete_profile_id = ap.id
            and tm.status = 'active'
        )
      )
  );
$$;

grant execute on function public.can_manage_attendance(uuid) to authenticated;
grant execute on function public.can_view_attendance(uuid, uuid) to authenticated;
grant execute on function public.is_valid_attendance_row(uuid, uuid) to authenticated;

drop policy if exists "attendance_select_authorized" on public.attendance;
drop policy if exists "attendance_manage_staff" on public.attendance;
drop policy if exists "attendance_insert_authorized" on public.attendance;
drop policy if exists "attendance_update_authorized" on public.attendance;
drop policy if exists "attendance_delete_authorized" on public.attendance;

create policy "attendance_select_authorized"
on public.attendance
for select
to authenticated
using (
  public.can_view_attendance(event_id, athlete_profile_id)
);

create policy "attendance_insert_authorized"
on public.attendance
for insert
to authenticated
with check (
  public.can_manage_attendance(event_id)
  and public.is_valid_attendance_row(event_id, athlete_profile_id)
);

create policy "attendance_update_authorized"
on public.attendance
for update
to authenticated
using (
  public.can_manage_attendance(event_id)
)
with check (
  public.can_manage_attendance(event_id)
  and public.is_valid_attendance_row(event_id, athlete_profile_id)
);

create policy "attendance_delete_authorized"
on public.attendance
for delete
to authenticated
using (
  public.can_manage_attendance(event_id)
);