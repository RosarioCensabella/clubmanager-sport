-- ClubManager Sport
-- Invitation email delivery
-- Version: 20260511001800

alter table public.invitations
add column if not exists email_sent_at timestamptz;

alter table public.invitations
add column if not exists email_last_error text;

alter table public.invitations
add column if not exists email_send_attempts integer not null default 0;

create index if not exists invitations_email_sent_at_idx
on public.invitations (email_sent_at);

notify pgrst, 'reload schema';