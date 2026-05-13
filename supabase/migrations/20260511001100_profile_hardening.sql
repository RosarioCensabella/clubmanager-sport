-- ClubManager Sport
-- Profile hardening
-- Version: 20260511001100

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  phone_number text,
  avatar_url text,
  preferred_language text not null default 'it',
  marketing_consent boolean not null default false,
  onboarding_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
add column if not exists email text;

alter table public.profiles
add column if not exists full_name text;

alter table public.profiles
add column if not exists phone_number text;

alter table public.profiles
add column if not exists avatar_url text;

alter table public.profiles
add column if not exists preferred_language text not null default 'it';

alter table public.profiles
add column if not exists marketing_consent boolean not null default false;

alter table public.profiles
add column if not exists onboarding_completed boolean not null default false;

update public.profiles
set preferred_language = 'it'
where preferred_language is null;

update public.profiles
set marketing_consent = false
where marketing_consent is null;

update public.profiles
set onboarding_completed = false
where onboarding_completed is null;

alter table public.profiles
drop constraint if exists profiles_preferred_language_check;

alter table public.profiles
add constraint profiles_preferred_language_check
check (
  preferred_language in ('it', 'en')
);

alter table public.profiles enable row level security;

drop trigger if exists profiles_set_updated_at on public.profiles;

create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

create or replace function public.handle_auth_user_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    full_name,
    created_at,
    updated_at
  )
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    now(),
    now()
  )
  on conflict (id) do update
  set
    email = excluded.email,
    updated_at = now();

  insert into public.notification_preferences (
    user_id,
    push_enabled,
    event_notifications_enabled,
    communication_notifications_enabled,
    document_notifications_enabled,
    fee_notifications_enabled,
    created_at,
    updated_at
  )
  values (
    new.id,
    true,
    true,
    true,
    true,
    true,
    now(),
    now()
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_auth_user_created();

drop policy if exists "profiles_select_own_or_same_club" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;

create policy "profiles_select_own"
on public.profiles
for select
to authenticated
using (
  id = auth.uid()
);

create policy "profiles_insert_own"
on public.profiles
for insert
to authenticated
with check (
  id = auth.uid()
);

create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (
  id = auth.uid()
)
with check (
  id = auth.uid()
);

notify pgrst, 'reload schema';