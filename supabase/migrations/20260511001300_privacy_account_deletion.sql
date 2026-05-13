-- ClubManager Sport
-- Privacy and account deletion requests
-- Version: 20260511001300
--
-- Nota:
-- In alcuni schema precedenti la colonna status può essere un enum
-- account_deletion_status. Per evitare incompatibilità con i valori app
-- la normalizziamo a text con constraint applicativa.

create extension if not exists pgcrypto;

create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  status text,
  reason text,
  requested_at timestamptz,
  cancelled_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz
);

alter table public.account_deletion_requests
add column if not exists user_id uuid references auth.users(id) on delete cascade;

alter table public.account_deletion_requests
add column if not exists status text;

alter table public.account_deletion_requests
add column if not exists reason text;

alter table public.account_deletion_requests
add column if not exists requested_at timestamptz;

alter table public.account_deletion_requests
add column if not exists cancelled_at timestamptz;

alter table public.account_deletion_requests
add column if not exists completed_at timestamptz;

alter table public.account_deletion_requests
add column if not exists created_at timestamptz;

alter table public.account_deletion_requests
add column if not exists updated_at timestamptz;

alter table public.account_deletion_requests
drop constraint if exists account_deletion_requests_status_check;

alter table public.account_deletion_requests
alter column status drop default;

alter table public.account_deletion_requests
alter column status type text
using status::text;

update public.account_deletion_requests
set status = case
  when status is null then 'pending'
  when status in ('pending', 'cancelled', 'completed', 'rejected') then status
  when status in ('requested', 'open', 'created') then 'pending'
  when status in ('done', 'deleted', 'processed') then 'completed'
  when status in ('canceled') then 'cancelled'
  else 'pending'
end;

update public.account_deletion_requests
set requested_at = coalesce(requested_at, created_at, now())
where requested_at is null;

update public.account_deletion_requests
set created_at = coalesce(created_at, requested_at, now())
where created_at is null;

update public.account_deletion_requests
set updated_at = coalesce(updated_at, now())
where updated_at is null;

alter table public.account_deletion_requests
alter column user_id set not null;

alter table public.account_deletion_requests
alter column status set not null;

alter table public.account_deletion_requests
alter column status set default 'pending';

alter table public.account_deletion_requests
alter column requested_at set not null;

alter table public.account_deletion_requests
alter column requested_at set default now();

alter table public.account_deletion_requests
alter column created_at set not null;

alter table public.account_deletion_requests
alter column created_at set default now();

alter table public.account_deletion_requests
alter column updated_at set not null;

alter table public.account_deletion_requests
alter column updated_at set default now();

alter table public.account_deletion_requests
add constraint account_deletion_requests_status_check
check (
  status in ('pending', 'cancelled', 'completed', 'rejected')
);

create index if not exists account_deletion_requests_user_id_idx
on public.account_deletion_requests (user_id);

create index if not exists account_deletion_requests_status_idx
on public.account_deletion_requests (status);

create unique index if not exists account_deletion_requests_one_pending_per_user_idx
on public.account_deletion_requests (user_id)
where status = 'pending';

alter table public.account_deletion_requests enable row level security;

drop trigger if exists account_deletion_requests_set_updated_at
on public.account_deletion_requests;

create trigger account_deletion_requests_set_updated_at
before update on public.account_deletion_requests
for each row
execute function public.set_updated_at();

drop policy if exists "account_deletion_requests_manage_own"
on public.account_deletion_requests;

drop policy if exists "account_deletion_requests_select_own"
on public.account_deletion_requests;

drop policy if exists "account_deletion_requests_insert_own"
on public.account_deletion_requests;

drop policy if exists "account_deletion_requests_update_own"
on public.account_deletion_requests;

create policy "account_deletion_requests_select_own"
on public.account_deletion_requests
for select
to authenticated
using (
  user_id = auth.uid()
);

create policy "account_deletion_requests_insert_own"
on public.account_deletion_requests
for insert
to authenticated
with check (
  user_id = auth.uid()
);

create policy "account_deletion_requests_update_own"
on public.account_deletion_requests
for update
to authenticated
using (
  user_id = auth.uid()
)
with check (
  user_id = auth.uid()
);

notify pgrst, 'reload schema';