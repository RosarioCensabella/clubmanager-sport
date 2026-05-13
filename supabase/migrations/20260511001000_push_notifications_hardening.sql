-- ClubManager Sport
-- Push notifications hardening
-- Version: 20260511001000

create extension if not exists pgcrypto;

create table if not exists public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null,
  device_id text,
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.push_tokens
add column if not exists user_id uuid references auth.users(id) on delete cascade;

alter table public.push_tokens
add column if not exists token text;

alter table public.push_tokens
add column if not exists platform text;

alter table public.push_tokens
add column if not exists device_id text;

alter table public.push_tokens
add column if not exists is_active boolean not null default true;

alter table public.push_tokens
add column if not exists last_seen_at timestamptz not null default now();

update public.push_tokens
set is_active = true
where is_active is null;

update public.push_tokens
set last_seen_at = now()
where last_seen_at is null;

alter table public.push_tokens
drop constraint if exists push_tokens_platform_check;

alter table public.push_tokens
add constraint push_tokens_platform_check
check (
  platform in ('android', 'ios', 'web', 'macos', 'windows', 'linux', 'unknown')
);

create index if not exists push_tokens_user_id_idx
on public.push_tokens (user_id);

create index if not exists push_tokens_token_idx
on public.push_tokens (token);

create unique index if not exists push_tokens_user_token_unique_idx
on public.push_tokens (user_id, token);

create table if not exists public.notification_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  push_enabled boolean not null default true,
  event_notifications_enabled boolean not null default true,
  communication_notifications_enabled boolean not null default true,
  document_notifications_enabled boolean not null default true,
  fee_notifications_enabled boolean not null default true,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

alter table public.notification_preferences
add column if not exists push_enabled boolean not null default true;

alter table public.notification_preferences
add column if not exists event_notifications_enabled boolean not null default true;

alter table public.notification_preferences
add column if not exists communication_notifications_enabled boolean not null default true;

alter table public.notification_preferences
add column if not exists document_notifications_enabled boolean not null default true;

alter table public.notification_preferences
add column if not exists fee_notifications_enabled boolean not null default true;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  club_id uuid references public.clubs(id) on delete cascade,
  recipient_user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null default 'generic',
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  sent_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.notifications
add column if not exists club_id uuid references public.clubs(id) on delete cascade;

alter table public.notifications
add column if not exists recipient_user_id uuid references auth.users(id) on delete cascade;

alter table public.notifications
add column if not exists title text;

alter table public.notifications
add column if not exists body text;

alter table public.notifications
add column if not exists type text not null default 'generic';

alter table public.notifications
add column if not exists data jsonb not null default '{}'::jsonb;

alter table public.notifications
add column if not exists read_at timestamptz;

alter table public.notifications
add column if not exists sent_at timestamptz;

create index if not exists notifications_recipient_user_id_idx
on public.notifications (recipient_user_id);

create index if not exists notifications_club_id_idx
on public.notifications (club_id);

alter table public.push_tokens enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.notifications enable row level security;

drop trigger if exists push_tokens_set_updated_at on public.push_tokens;
drop trigger if exists notification_preferences_set_updated_at on public.notification_preferences;

create trigger push_tokens_set_updated_at
before update on public.push_tokens
for each row
execute function public.set_updated_at();

create trigger notification_preferences_set_updated_at
before update on public.notification_preferences
for each row
execute function public.set_updated_at();

drop policy if exists "push_tokens_manage_own" on public.push_tokens;
drop policy if exists "notification_preferences_manage_own" on public.notification_preferences;
drop policy if exists "notifications_select_own" on public.notifications;
drop policy if exists "notifications_update_own" on public.notifications;
drop policy if exists "notifications_insert_own" on public.notifications;

create policy "push_tokens_manage_own"
on public.push_tokens
for all
to authenticated
using (
  user_id = auth.uid()
)
with check (
  user_id = auth.uid()
);

create policy "notification_preferences_manage_own"
on public.notification_preferences
for all
to authenticated
using (
  user_id = auth.uid()
)
with check (
  user_id = auth.uid()
);

create policy "notifications_select_own"
on public.notifications
for select
to authenticated
using (
  recipient_user_id = auth.uid()
);

create policy "notifications_update_own"
on public.notifications
for update
to authenticated
using (
  recipient_user_id = auth.uid()
)
with check (
  recipient_user_id = auth.uid()
);

create policy "notifications_insert_own"
on public.notifications
for insert
to authenticated
with check (
  recipient_user_id = auth.uid()
);

notify pgrst, 'reload schema';