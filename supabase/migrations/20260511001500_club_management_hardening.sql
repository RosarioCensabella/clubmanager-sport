-- ClubManager Sport
-- Club management hardening
-- Version: 20260511001500

alter table public.clubs
add column if not exists archived_at timestamptz;

alter table public.clubs
add column if not exists archived_by uuid references auth.users(id) on delete set null;

alter table public.clubs
add column if not exists archive_reason text;

create index if not exists clubs_deleted_at_idx on public.clubs (deleted_at);
create index if not exists clubs_archived_at_idx on public.clubs (archived_at);

notify pgrst, 'reload schema';