-- ClubManager Sport
-- Settings and notification preferences hardening
-- Version: 20260511001200

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

update public.notification_preferences
set
  push_enabled = coalesce(push_enabled, true),
  event_notifications_enabled = coalesce(event_notifications_enabled, true),
  communication_notifications_enabled = coalesce(communication_notifications_enabled, true),
  document_notifications_enabled = coalesce(document_notifications_enabled, true),
  fee_notifications_enabled = coalesce(fee_notifications_enabled, true);

alter table public.notification_preferences enable row level security;

drop trigger if exists notification_preferences_set_updated_at on public.notification_preferences;

create trigger notification_preferences_set_updated_at
before update on public.notification_preferences
for each row
execute function public.set_updated_at();

drop policy if exists "notification_preferences_manage_own" on public.notification_preferences;
drop policy if exists "notification_preferences_select_own" on public.notification_preferences;
drop policy if exists "notification_preferences_insert_own" on public.notification_preferences;
drop policy if exists "notification_preferences_update_own" on public.notification_preferences;

create policy "notification_preferences_select_own"
on public.notification_preferences
for select
to authenticated
using (
  user_id = auth.uid()
);

create policy "notification_preferences_insert_own"
on public.notification_preferences
for insert
to authenticated
with check (
  user_id = auth.uid()
);

create policy "notification_preferences_update_own"
on public.notification_preferences
for update
to authenticated
using (
  user_id = auth.uid()
)
with check (
  user_id = auth.uid()
);

notify pgrst, 'reload schema';