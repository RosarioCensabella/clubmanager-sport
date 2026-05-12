-- ClubManager Sport
-- RSVP fields on event callups
-- Version: 20260511000500

alter table public.event_callups
add column if not exists response_note text;

alter table public.event_callups
add column if not exists responded_by uuid references auth.users(id) on delete set null;

alter table public.event_callups
add column if not exists responded_at timestamptz;

alter table public.event_callups
drop constraint if exists event_callups_status_check;

alter table public.event_callups
add constraint event_callups_status_check
check (
  status in (
    'called',
    'confirmed',
    'declined',
    'removed'
  )
);