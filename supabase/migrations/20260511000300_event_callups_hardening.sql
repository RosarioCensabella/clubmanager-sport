-- ClubManager Sport
-- Event callups hardening
-- Version: 20260511000300

alter table public.event_callups
add column if not exists status text not null default 'called';

alter table public.event_callups
add column if not exists notes text;

alter table public.event_callups
add column if not exists created_by uuid references auth.users(id) on delete set null;

alter table public.event_callups
add column if not exists created_at timestamptz not null default now();

alter table public.event_callups
add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'event_callups_event_athlete_unique'
  ) then
    alter table public.event_callups
    add constraint event_callups_event_athlete_unique
    unique (event_id, athlete_profile_id);
  end if;
end $$;

drop trigger if exists event_callups_set_updated_at on public.event_callups;

create trigger event_callups_set_updated_at
before update on public.event_callups
for each row
execute function public.set_updated_at();