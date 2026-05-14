-- ClubManager Sport
-- Athlete management hardening
-- Version: 20260511001700

alter table public.athlete_profiles
add column if not exists archived_at timestamptz;

alter table public.athlete_profiles
add column if not exists archived_by uuid references auth.users(id) on delete set null;

alter table public.athlete_profiles
add column if not exists archive_reason text;

create index if not exists athlete_profiles_deleted_at_idx on public.athlete_profiles (deleted_at);
create index if not exists athlete_profiles_archived_at_idx on public.athlete_profiles (archived_at);

notify pgrst, 'reload schema';