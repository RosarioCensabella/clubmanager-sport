-- ClubManager Sport
-- Communications hardening
-- Version: 20260511000700

create extension if not exists pgcrypto;

do $$
declare
  status_type regtype;
  priority_type regtype;
  visibility_type regtype;
begin
  select atttypid::regtype
  into status_type
  from pg_attribute
  where attrelid = 'public.announcements'::regclass
    and attname = 'status'
    and not attisdropped;

  if status_type is not null and status_type::text <> 'text' then
    execute format('alter type %s add value if not exists %L', status_type, 'draft');
    execute format('alter type %s add value if not exists %L', status_type, 'published');
    execute format('alter type %s add value if not exists %L', status_type, 'archived');
  end if;

  select atttypid::regtype
  into priority_type
  from pg_attribute
  where attrelid = 'public.announcements'::regclass
    and attname = 'priority'
    and not attisdropped;

  if priority_type is not null and priority_type::text <> 'text' then
    execute format('alter type %s add value if not exists %L', priority_type, 'normal');
    execute format('alter type %s add value if not exists %L', priority_type, 'important');
    execute format('alter type %s add value if not exists %L', priority_type, 'urgent');
  end if;

  select atttypid::regtype
  into visibility_type
  from pg_attribute
  where attrelid = 'public.announcements'::regclass
    and attname = 'visibility'
    and not attisdropped;

  if visibility_type is not null and visibility_type::text <> 'text' then
    execute format('alter type %s add value if not exists %L', visibility_type, 'club');
    execute format('alter type %s add value if not exists %L', visibility_type, 'team');
  end if;
exception
  when undefined_table then
    null;
end $$;

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  team_id uuid references public.teams(id) on delete set null,
  title text not null,
  body text,
  content text,
  priority text not null default 'normal',
  visibility text not null default 'club',
  status text not null default 'published',
  allow_comments boolean not null default true,
  send_push boolean not null default false,
  pinned boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  published_at timestamptz,
  publish_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table public.announcements
add column if not exists team_id uuid references public.teams(id) on delete set null;

alter table public.announcements
add column if not exists body text;

alter table public.announcements
add column if not exists content text;

alter table public.announcements
add column if not exists priority text;

alter table public.announcements
add column if not exists visibility text;

alter table public.announcements
add column if not exists status text;

alter table public.announcements
add column if not exists allow_comments boolean not null default true;

alter table public.announcements
add column if not exists send_push boolean not null default false;

alter table public.announcements
add column if not exists pinned boolean not null default false;

alter table public.announcements
add column if not exists created_by uuid references auth.users(id) on delete set null;

alter table public.announcements
add column if not exists published_at timestamptz;

alter table public.announcements
add column if not exists publish_at timestamptz;

alter table public.announcements
add column if not exists expires_at timestamptz;

alter table public.announcements
add column if not exists deleted_at timestamptz;

update public.announcements
set body = coalesce(body, content)
where body is null;

update public.announcements
set content = coalesce(content, body)
where content is null;

alter table public.announcements
drop constraint if exists announcements_priority_check;

alter table public.announcements
add constraint announcements_priority_check
check (
  priority::text in ('normal', 'important', 'urgent')
);

alter table public.announcements
drop constraint if exists announcements_visibility_check;

alter table public.announcements
add constraint announcements_visibility_check
check (
  visibility::text in ('club', 'team')
);

alter table public.announcements
drop constraint if exists announcements_status_check;

alter table public.announcements
add constraint announcements_status_check
check (
  status::text in ('draft', 'published', 'archived')
);

alter table public.announcements enable row level security;

drop trigger if exists announcements_set_updated_at on public.announcements;

create trigger announcements_set_updated_at
before update on public.announcements
for each row
execute function public.set_updated_at();

create table if not exists public.announcement_reads (
  announcement_id uuid not null references public.announcements(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (announcement_id, user_id)
);

alter table public.announcement_reads enable row level security;

create or replace function public.can_manage_announcements(p_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.club_memberships cm
    where cm.club_id = p_club_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('owner', 'admin', 'team_manager', 'coach', 'staff')
  );
$$;

create or replace function public.can_view_announcement(
  p_announcement_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.announcements a
    join public.club_memberships cm
      on cm.club_id = a.club_id
    where a.id = p_announcement_id
      and a.deleted_at is null
      and a.status::text = 'published'
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and (
        a.team_id is null
        or exists (
          select 1
          from public.team_memberships tm
          join public.athlete_profiles ap
            on ap.id = tm.athlete_profile_id
          where tm.team_id = a.team_id
            and tm.status = 'active'
            and (
              ap.user_id = auth.uid()
              or exists (
                select 1
                from public.parent_athlete_relations par
                where par.athlete_profile_id = ap.id
                  and par.parent_user_id = auth.uid()
              )
            )
        )
        or cm.role in ('owner', 'admin', 'team_manager', 'coach', 'staff')
      )
  );
$$;

grant execute on function public.can_manage_announcements(uuid) to authenticated;
grant execute on function public.can_view_announcement(uuid) to authenticated;

drop policy if exists "announcements_select_targets" on public.announcements;
drop policy if exists "announcements_manage_staff" on public.announcements;
drop policy if exists "announcements_select_authorized" on public.announcements;
drop policy if exists "announcements_insert_authorized" on public.announcements;
drop policy if exists "announcements_update_authorized" on public.announcements;
drop policy if exists "announcements_delete_authorized" on public.announcements;

create policy "announcements_select_authorized"
on public.announcements
for select
to authenticated
using (
  public.can_view_announcement(id)
  or public.can_manage_announcements(club_id)
);

create policy "announcements_insert_authorized"
on public.announcements
for insert
to authenticated
with check (
  public.can_manage_announcements(club_id)
);

create policy "announcements_update_authorized"
on public.announcements
for update
to authenticated
using (
  public.can_manage_announcements(club_id)
)
with check (
  public.can_manage_announcements(club_id)
);

create policy "announcements_delete_authorized"
on public.announcements
for delete
to authenticated
using (
  public.can_manage_announcements(club_id)
);

drop policy if exists "announcement_reads_manage_own" on public.announcement_reads;

create policy "announcement_reads_manage_own"
on public.announcement_reads
for all
to authenticated
using (
  user_id = auth.uid()
)
with check (
  user_id = auth.uid()
  and public.can_view_announcement(announcement_id)
);