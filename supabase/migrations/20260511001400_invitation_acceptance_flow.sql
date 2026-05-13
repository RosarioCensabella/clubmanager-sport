-- ClubManager Sport
-- Invitation acceptance flow
-- Version: 20260511001400

create extension if not exists pgcrypto;

alter table public.invitations
add column if not exists accepted_at timestamptz;

alter table public.invitations
add column if not exists accepted_by uuid references auth.users(id) on delete set null;

alter table public.invitations
add column if not exists revoked_at timestamptz;

alter table public.invitations
add column if not exists revoked_by uuid references auth.users(id) on delete set null;

alter table public.invitations
add column if not exists invite_type text not null default 'membership';

alter table public.invitations
add column if not exists metadata jsonb not null default '{}'::jsonb;

alter table public.invitations
drop constraint if exists invitations_status_check;

alter table public.invitations
alter column status drop default;

alter table public.invitations
alter column status type text
using status::text;

update public.invitations
set status = case
  when status is null then 'sent'
  when status in ('draft', 'sent', 'accepted', 'expired', 'revoked', 'cancelled') then status
  when status in ('pending', 'open', 'created') then 'sent'
  when status in ('canceled') then 'cancelled'
  else 'sent'
end;

alter table public.invitations
alter column status set default 'sent';

alter table public.invitations
alter column status set not null;

alter table public.invitations
add constraint invitations_status_check
check (
  status in ('draft', 'sent', 'accepted', 'expired', 'revoked', 'cancelled')
);

create unique index if not exists invitations_token_unique_idx
on public.invitations (token);

create index if not exists invitations_email_idx
on public.invitations (lower(email));

create index if not exists invitations_status_idx
on public.invitations (status);

drop function if exists public.get_invitation_by_token(text);

create or replace function public.get_invitation_by_token(invitation_token text)
returns table (
  id uuid,
  club_id uuid,
  team_id uuid,
  email text,
  role text,
  status text,
  token text,
  expires_at timestamptz,
  created_at timestamptz,
  club_name text,
  team_name text
)
language sql
security definer
set search_path = public
as $$
  select
    invitations.id,
    invitations.club_id,
    invitations.team_id,
    invitations.email,
    invitations.role::text as role,
    case
      when invitations.status = 'sent'
        and invitations.expires_at is not null
        and invitations.expires_at < now()
      then 'expired'
      else invitations.status
    end as status,
    invitations.token,
    invitations.expires_at,
    invitations.created_at,
    clubs.name as club_name,
    teams.name as team_name
  from public.invitations
  join public.clubs on clubs.id = invitations.club_id
  left join public.teams on teams.id = invitations.team_id
  where invitations.token = invitation_token
  limit 1;
$$;

grant execute on function public.get_invitation_by_token(text) to anon;
grant execute on function public.get_invitation_by_token(text) to authenticated;

drop function if exists public.accept_invitation(text);

create or replace function public.accept_invitation(invitation_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  invitation_record record;
  current_user_id uuid;
  current_email text;
  membership_role_type text;
  role_expression text;
  affected_rows integer;
begin
  current_user_id := auth.uid();
  current_email := lower(coalesce(auth.jwt() ->> 'email', ''));

  if current_user_id is null then
    raise exception 'Devi effettuare l’accesso per accettare l’invito.';
  end if;

  select *
  into invitation_record
  from public.invitations
  where token = invitation_token
  for update;

  if not found then
    raise exception 'Invito non trovato.';
  end if;

  if invitation_record.status <> 'sent' then
    raise exception 'Questo invito non è più valido.';
  end if;

  if invitation_record.expires_at is not null and invitation_record.expires_at < now() then
    update public.invitations
    set status = 'expired'
    where id = invitation_record.id;

    raise exception 'Questo invito è scaduto.';
  end if;

  if lower(invitation_record.email) <> current_email then
    raise exception 'Questo invito è associato a un’altra email.';
  end if;

  select format_type(attribute.atttypid, attribute.atttypmod)
  into membership_role_type
  from pg_attribute attribute
  join pg_class class on class.oid = attribute.attrelid
  join pg_namespace namespace on namespace.oid = class.relnamespace
  where namespace.nspname = 'public'
    and class.relname = 'club_memberships'
    and attribute.attname = 'role'
    and not attribute.attisdropped
  limit 1;

  if membership_role_type is null then
    raise exception 'Schema membership non valido.';
  end if;

  if membership_role_type in ('text', 'character varying') then
    role_expression := '$3';
  else
    role_expression := '$3::' || membership_role_type;
  end if;

  execute
    'update public.club_memberships ' ||
    'set role = ' || role_expression || ' ' ||
    'where club_id = $1 and user_id = $2'
  using invitation_record.club_id, current_user_id, invitation_record.role::text;

  get diagnostics affected_rows = row_count;

  if affected_rows = 0 then
    execute
      'insert into public.club_memberships (club_id, user_id, role) ' ||
      'values ($1, $2, ' || role_expression || ')'
    using invitation_record.club_id, current_user_id, invitation_record.role::text;
  end if;

  update public.invitations
  set
    status = 'accepted',
    accepted_at = now(),
    accepted_by = current_user_id
  where id = invitation_record.id;

  return jsonb_build_object(
    'ok', true,
    'club_id', invitation_record.club_id,
    'invitation_id', invitation_record.id
  );
end;
$$;

grant execute on function public.accept_invitation(text) to authenticated;

notify pgrst, 'reload schema';