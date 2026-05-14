-- ClubManager Sport
-- Member access actions RPC
-- Version: 20260511001910

create or replace function public.member_access_is_club_admin(target_club_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.club_memberships cm
    where cm.club_id = target_club_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('owner', 'admin')
  );
$$;

create or replace function public.member_access_assign_user_to_team(
  target_club_id uuid,
  target_user_id uuid,
  target_team_id uuid,
  target_role text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_role public.club_role;
  existing_membership public.club_memberships%rowtype;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.member_access_is_club_admin(target_club_id) then
    raise exception 'not_authorized';
  end if;

  if target_club_id is null or target_user_id is null or target_team_id is null then
    raise exception 'invalid_team_assignment';
  end if;

  if target_role not in ('team_manager', 'coach', 'staff') then
    raise exception 'invalid_team_role';
  end if;

  normalized_role := target_role::public.club_role;

  if not exists (
    select 1
    from public.teams t
    where t.id = target_team_id
      and t.club_id = target_club_id
      and t.deleted_at is null
  ) then
    raise exception 'team_not_found';
  end if;

  select *
  into existing_membership
  from public.club_memberships cm
  where cm.club_id = target_club_id
    and cm.user_id = target_user_id
  limit 1;

  if not found then
    insert into public.club_memberships (
      club_id,
      user_id,
      role,
      status
    )
    values (
      target_club_id,
      target_user_id,
      normalized_role,
      'active'
    );
  else
    update public.club_memberships
    set
      role = case
        when existing_membership.role in ('owner', 'admin') then existing_membership.role
        else normalized_role
      end,
      status = 'active',
      updated_at = now()
    where id = existing_membership.id;
  end if;

  insert into public.team_memberships (
    team_id,
    user_id,
    role,
    status
  )
  values (
    target_team_id,
    target_user_id,
    normalized_role,
    'active'
  )
  on conflict (team_id, user_id, role) do update
  set
    status = 'active',
    updated_at = now();
end;
$$;

create or replace function public.member_access_link_parent_to_athlete(
  target_club_id uuid,
  target_parent_user_id uuid,
  target_athlete_id uuid,
  target_relation_type text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_relation_type text;
  existing_membership public.club_memberships%rowtype;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.member_access_is_club_admin(target_club_id) then
    raise exception 'not_authorized';
  end if;

  if target_club_id is null or target_parent_user_id is null or target_athlete_id is null then
    raise exception 'invalid_parent_relation';
  end if;

  normalized_relation_type := coalesce(nullif(btrim(target_relation_type), ''), 'parent');

  if normalized_relation_type not in ('parent', 'mother', 'father', 'guardian') then
    normalized_relation_type := 'parent';
  end if;

  if not exists (
    select 1
    from public.athlete_profiles ap
    where ap.id = target_athlete_id
      and ap.club_id = target_club_id
      and ap.deleted_at is null
  ) then
    raise exception 'athlete_not_found';
  end if;

  select *
  into existing_membership
  from public.club_memberships cm
  where cm.club_id = target_club_id
    and cm.user_id = target_parent_user_id
  limit 1;

  if not found then
    insert into public.club_memberships (
      club_id,
      user_id,
      role,
      status
    )
    values (
      target_club_id,
      target_parent_user_id,
      'parent',
      'active'
    );
  else
    update public.club_memberships
    set
      role = case
        when existing_membership.role in ('owner', 'admin', 'team_manager', 'coach', 'staff') then existing_membership.role
        else 'parent'::public.club_role
      end,
      status = 'active',
      updated_at = now()
    where id = existing_membership.id;
  end if;

  insert into public.parent_athlete_relations (
    parent_user_id,
    athlete_profile_id,
    relation_type,
    verified
  )
  values (
    target_parent_user_id,
    target_athlete_id,
    normalized_relation_type,
    true
  )
  on conflict (parent_user_id, athlete_profile_id) do update
  set
    relation_type = excluded.relation_type,
    verified = true;
end;
$$;

create or replace function public.member_access_link_athlete_account(
  target_club_id uuid,
  target_athlete_user_id uuid,
  target_athlete_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  athlete_row public.athlete_profiles%rowtype;
  existing_membership public.club_memberships%rowtype;
  existing_team_membership_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.member_access_is_club_admin(target_club_id) then
    raise exception 'not_authorized';
  end if;

  if target_club_id is null or target_athlete_user_id is null or target_athlete_id is null then
    raise exception 'invalid_athlete_account_link';
  end if;

  select *
  into athlete_row
  from public.athlete_profiles ap
  where ap.id = target_athlete_id
    and ap.club_id = target_club_id
    and ap.deleted_at is null
  limit 1;

  if not found then
    raise exception 'athlete_not_found';
  end if;

  if athlete_row.user_id is not null and athlete_row.user_id <> target_athlete_user_id then
    raise exception 'athlete_already_linked';
  end if;

  select *
  into existing_membership
  from public.club_memberships cm
  where cm.club_id = target_club_id
    and cm.user_id = target_athlete_user_id
  limit 1;

  if not found then
    insert into public.club_memberships (
      club_id,
      user_id,
      role,
      status
    )
    values (
      target_club_id,
      target_athlete_user_id,
      'athlete',
      'active'
    );
  else
    update public.club_memberships
    set
      role = case
        when existing_membership.role in ('owner', 'admin', 'team_manager', 'coach', 'staff') then existing_membership.role
        else 'athlete'::public.club_role
      end,
      status = 'active',
      updated_at = now()
    where id = existing_membership.id;
  end if;

  update public.athlete_profiles
  set
    user_id = target_athlete_user_id,
    active = true,
    updated_at = now()
  where id = target_athlete_id;

  if athlete_row.team_id is null then
    return;
  end if;

  select tm.id
  into existing_team_membership_id
  from public.team_memberships tm
  where tm.team_id = athlete_row.team_id
    and tm.athlete_profile_id = target_athlete_id
    and tm.role = 'athlete'
  limit 1;

  if existing_team_membership_id is not null then
    update public.team_memberships
    set
      user_id = target_athlete_user_id,
      status = 'active',
      updated_at = now()
    where id = existing_team_membership_id;

    return;
  end if;

  insert into public.team_memberships (
    team_id,
    user_id,
    athlete_profile_id,
    role,
    status
  )
  values (
    athlete_row.team_id,
    target_athlete_user_id,
    target_athlete_id,
    'athlete',
    'active'
  )
  on conflict (team_id, user_id, role) do update
  set
    athlete_profile_id = coalesce(
      public.team_memberships.athlete_profile_id,
      excluded.athlete_profile_id
    ),
    status = 'active',
    updated_at = now();
end;
$$;

create or replace function public.member_access_update_member(
  target_club_id uuid,
  target_membership_id uuid,
  target_role text,
  target_status text,
  target_first_name text default null,
  target_last_name text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  membership_row public.club_memberships%rowtype;
  normalized_role public.club_role;
  normalized_status public.membership_status;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.member_access_is_club_admin(target_club_id) then
    raise exception 'not_authorized';
  end if;

  if target_club_id is null or target_membership_id is null then
    raise exception 'invalid_member';
  end if;

  if target_role not in ('admin', 'team_manager', 'coach', 'staff', 'athlete', 'parent') then
    raise exception 'invalid_member_role';
  end if;

  if target_status not in ('active', 'pending', 'suspended', 'removed') then
    raise exception 'invalid_member_status';
  end if;

  normalized_role := target_role::public.club_role;
  normalized_status := target_status::public.membership_status;

  select *
  into membership_row
  from public.club_memberships cm
  where cm.id = target_membership_id
    and cm.club_id = target_club_id
  limit 1;

  if not found then
    raise exception 'member_not_found';
  end if;

  if membership_row.role = 'owner' then
    raise exception 'owner_cannot_be_modified';
  end if;

  update public.club_memberships
  set
    role = normalized_role,
    status = normalized_status,
    updated_at = now()
  where id = membership_row.id;

  update public.profiles
  set
    first_name = nullif(btrim(coalesce(target_first_name, '')), ''),
    last_name = nullif(btrim(coalesce(target_last_name, '')), ''),
    updated_at = now()
  where id = membership_row.user_id;
end;
$$;

grant execute on function public.member_access_is_club_admin(uuid) to authenticated;
grant execute on function public.member_access_assign_user_to_team(uuid, uuid, uuid, text) to authenticated;
grant execute on function public.member_access_link_parent_to_athlete(uuid, uuid, uuid, text) to authenticated;
grant execute on function public.member_access_link_athlete_account(uuid, uuid, uuid) to authenticated;
grant execute on function public.member_access_update_member(uuid, uuid, text, text, text, text) to authenticated;

notify pgrst, 'reload schema';