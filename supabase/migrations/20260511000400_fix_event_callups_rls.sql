-- ClubManager Sport
-- Fix RLS policies for event callups
-- Version: 20260511000400

create or replace function public.can_manage_event_callups(p_event_id uuid)
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

create or replace function public.can_view_event_callups(
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

create or replace function public.is_valid_event_callup(
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

grant execute on function public.can_manage_event_callups(uuid) to authenticated;
grant execute on function public.can_view_event_callups(uuid, uuid) to authenticated;
grant execute on function public.is_valid_event_callup(uuid, uuid) to authenticated;

drop policy if exists "event_callups_select_authorized" on public.event_callups;
drop policy if exists "event_callups_manage_team_staff" on public.event_callups;
drop policy if exists "event_callups_insert_authorized" on public.event_callups;
drop policy if exists "event_callups_update_authorized" on public.event_callups;
drop policy if exists "event_callups_delete_authorized" on public.event_callups;

create policy "event_callups_select_authorized"
on public.event_callups
for select
to authenticated
using (
  public.can_view_event_callups(event_id, athlete_profile_id)
);

create policy "event_callups_insert_authorized"
on public.event_callups
for insert
to authenticated
with check (
  public.can_manage_event_callups(event_id)
  and public.is_valid_event_callup(event_id, athlete_profile_id)
);

create policy "event_callups_update_authorized"
on public.event_callups
for update
to authenticated
using (
  public.can_manage_event_callups(event_id)
)
with check (
  public.can_manage_event_callups(event_id)
  and public.is_valid_event_callup(event_id, athlete_profile_id)
);

create policy "event_callups_delete_authorized"
on public.event_callups
for delete
to authenticated
using (
  public.can_manage_event_callups(event_id)
);