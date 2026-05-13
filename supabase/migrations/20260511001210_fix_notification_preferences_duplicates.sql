-- ClubManager Sport
-- Fix duplicated notification preferences
-- Version: 20260511001210

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
add column if not exists user_id uuid references auth.users(id) on delete cascade;

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

alter table public.notification_preferences
add column if not exists updated_at timestamptz not null default now();

alter table public.notification_preferences
add column if not exists created_at timestamptz not null default now();

delete from public.notification_preferences
where user_id is null;

update public.notification_preferences
set
  push_enabled = coalesce(push_enabled, true),
  event_notifications_enabled = coalesce(event_notifications_enabled, true),
  communication_notifications_enabled = coalesce(communication_notifications_enabled, true),
  document_notifications_enabled = coalesce(document_notifications_enabled, true),
  fee_notifications_enabled = coalesce(fee_notifications_enabled, true),
  updated_at = coalesce(updated_at, now()),
  created_at = coalesce(created_at, now());

with ranked_preferences as (
  select
    ctid,
    row_number() over (
      partition by user_id
      order by updated_at desc, created_at desc, ctid desc
    ) as row_number
  from public.notification_preferences
)
delete from public.notification_preferences preferences
using ranked_preferences ranked
where preferences.ctid = ranked.ctid
and ranked.row_number > 1;

create unique index if not exists notification_preferences_user_id_unique_idx
on public.notification_preferences (user_id);

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