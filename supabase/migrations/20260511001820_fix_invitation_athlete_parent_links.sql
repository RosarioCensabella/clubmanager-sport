-- ClubManager Sport
-- Fix invitation links for athlete and parent operational contexts
-- Version: 20260511001820

create extension if not exists pgcrypto with schema extensions;

alter table public.invitations
add column if not exists athlete_profile_id uuid references public.athlete_profiles(id) on delete set null;

alter table public.invitations
add column if not exists accepted_by uuid references auth.users(id) on delete set null;

alter table public.invitations
add column if not exists revoked_at timestamptz;

alter table public.invitations
add column if not exists email_sent_at timestamptz;

alter table public.invitations
add column if not exists email_last_error text;

alter table public.invitations
add column if not exists email_send_attempts integer not null default 0;

drop function if exists public.get_invitation_by_token(text);
drop function if exists public.accept_invitation(text);

create function public.get_invitation_by_token(invitation_token text)
returns table (
  id uuid,
  token text,
  club_id uuid,
  club_name text,
  team_id uuid,
  team_name text,
  athlete_profile_id uuid,
  athlete_name text,
  email text,
  role text,
  status text,
  expires_at timestamptz,
  is_valid boolean
)
language sql
security definer
set search_path = public
as $$
  select
    i.id,
    i.token,
    i.club_id,
    c.name as club_name,
    i.team_id,
    t.name as team_name,
    i.athlete_profile_id,
    nullif(concat_ws(' ', ap.first_name, ap.last_name), '') as athlete_name,
    i.email,
    i.role::text as role,
    i.status::text as status,
    i.expires_at,
    (
      i.status = 'sent'
      and i.expires_at > now()
    ) as is_valid
  from public.invitations i
  join public.clubs c
    on c.id = i.club_id
  left join public.teams t
    on t.id = i.team_id
  left join public.athlete_profiles ap
    on ap.id = i.athlete_profile_id
  where i.token = btrim(invitation_token)
  limit 1;
$$;

create function public.accept_invitation(invitation_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_invitation public.invitations%rowtype;
  current_user_id uuid;
  current_user_email text;
  already_accepted_by_current_user boolean := false;
  target_team_id uuid;
  updated_rows integer := 0;
begin
  current_user_id := auth.uid();
  current_user_email := lower(coalesce(auth.jwt() ->> 'email', ''));

  if current_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if invitation_token is null or btrim(invitation_token) = '' then
    raise exception 'invalid_invitation_token';
  end if;

  select *
  into target_invitation
  from public.invitations
  where token = btrim(invitation_token)
  for update;

  if not found then
    raise exception 'invitation_not_found';
  end if;

  if lower(target_invitation.email) <> current_user_email then
    raise exception 'invalid_invitation_email';
  end if;

  if target_invitation.status = 'accepted' then
    if target_invitation.accepted_by is null
       or target_invitation.accepted_by = current_user_id then
      already_accepted_by_current_user := true;
    else
      raise exception 'invitation_already_accepted';
    end if;
  elsif target_invitation.status <> 'sent' then
    raise exception 'invitation_not_available';
  end if;

  if not already_accepted_by_current_user
     and target_invitation.expires_at <= now() then
    raise exception 'invitation_expired';
  end if;

  target_team_id := target_invitation.team_id;

  if target_team_id is null and target_invitation.athlete_profile_id is not null then
    select team_id
    into target_team_id
    from public.athlete_profiles
    where id = target_invitation.athlete_profile_id;
  end if;

  if target_invitation.role = 'athlete'
     and target_invitation.athlete_profile_id is not null then
    if exists (
      select 1
      from public.athlete_profiles ap
      where ap.id = target_invitation.athlete_profile_id
        and ap.user_id is not null
        and ap.user_id <> current_user_id
    ) then
      raise exception 'athlete_profile_already_linked';
    end if;

    update public.athlete_profiles
    set
      user_id = current_user_id,
      active = true,
      updated_at = now()
    where id = target_invitation.athlete_profile_id
      and club_id = target_invitation.club_id
      and (
        user_id is null
        or user_id = current_user_id
      );
  end if;

  if target_invitation.role = 'parent'
     and target_invitation.athlete_profile_id is not null then
    insert into public.parent_athlete_relations (
      parent_user_id,
      athlete_profile_id,
      relation_type,
      verified
    )
    values (
      current_user_id,
      target_invitation.athlete_profile_id,
      'parent',
      true
    )
    on conflict (parent_user_id, athlete_profile_id) do update
    set
      verified = true,
      relation_type = coalesce(public.parent_athlete_relations.relation_type, 'parent');
  end if;

  insert into public.club_memberships (
    club_id,
    user_id,
    role,
    status
  )
  values (
    target_invitation.club_id,
    current_user_id,
    target_invitation.role,
    'active'
  )
  on conflict (club_id, user_id) do update
  set
    role = case
      when public.club_memberships.role in ('owner', 'admin') then public.club_memberships.role
      else excluded.role
    end,
    status = 'active',
    updated_at = now();

  if target_team_id is not null
     and target_invitation.role in ('athlete', 'coach', 'team_manager', 'staff') then

    if target_invitation.role = 'athlete'
       and target_invitation.athlete_profile_id is not null then

      update public.team_memberships
      set
        user_id = current_user_id,
        status = 'active',
        updated_at = now()
      where team_id = target_team_id
        and athlete_profile_id = target_invitation.athlete_profile_id
        and role = 'athlete';

      get diagnostics updated_rows = row_count;

      if updated_rows = 0 then
        insert into public.team_memberships (
          team_id,
          user_id,
          athlete_profile_id,
          role,
          status
        )
        values (
          target_team_id,
          current_user_id,
          target_invitation.athlete_profile_id,
          target_invitation.role,
          'active'
        )
        on conflict (team_id, user_id, role) do update
        set
          status = 'active',
          athlete_profile_id = coalesce(
            public.team_memberships.athlete_profile_id,
            excluded.athlete_profile_id
          ),
          updated_at = now();
      end if;

    else
      insert into public.team_memberships (
        team_id,
        user_id,
        athlete_profile_id,
        role,
        status
      )
      values (
        target_team_id,
        current_user_id,
        null,
        target_invitation.role,
        'active'
      )
      on conflict (team_id, user_id, role) do update
      set
        status = 'active',
        updated_at = now();
    end if;
  end if;

  update public.invitations
  set
    status = 'accepted',
    accepted_by = current_user_id,
    updated_at = now()
  where id = target_invitation.id;
end;
$$;

grant execute on function public.get_invitation_by_token(text) to anon;
grant execute on function public.get_invitation_by_token(text) to authenticated;

grant execute on function public.accept_invitation(text) to authenticated;

notify pgrst, 'reload schema';