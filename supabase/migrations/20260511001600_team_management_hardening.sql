-- ClubManager Sport
-- Team management hardening
-- Version: 20260511001600

alter table public.teams
add column if not exists archived_at timestamptz;

alter table public.teams
add column if not exists archived_by uuid references auth.users(id) on delete set null;

alter table public.teams
add column if not exists archive_reason text;

create index if not exists teams_deleted_at_idx on public.teams (deleted_at);
create index if not exists teams_archived_at_idx on public.teams (archived_at);

notify pgrst, 'reload schema';