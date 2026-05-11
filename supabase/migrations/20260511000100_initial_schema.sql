-- ClubManager Sport
-- Initial database schema
-- Version: 20260511000100

create extension if not exists pgcrypto with schema extensions;

-- =========================================================
-- ENUMS
-- =========================================================

do $$
begin
  if not exists (select 1 from pg_type where typname = 'club_role') then
    create type public.club_role as enum (
      'owner',
      'admin',
      'team_manager',
      'coach',
      'athlete',
      'parent',
      'staff'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'membership_status') then
    create type public.membership_status as enum (
      'active',
      'pending',
      'suspended',
      'removed'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'subscription_plan') then
    create type public.subscription_plan as enum (
      'free',
      'basic',
      'pro',
      'club',
      'enterprise'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'subscription_status') then
    create type public.subscription_status as enum (
      'trialing',
      'active',
      'past_due',
      'paused',
      'cancelled'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'invitation_status') then
    create type public.invitation_status as enum (
      'sent',
      'accepted',
      'expired',
      'revoked'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'team_gender') then
    create type public.team_gender as enum (
      'male',
      'female',
      'mixed',
      'unspecified'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'event_type') then
    create type public.event_type as enum (
      'training',
      'match',
      'tournament',
      'meeting',
      'medical_visit',
      'social_event',
      'payment_deadline',
      'other'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'event_status') then
    create type public.event_status as enum (
      'scheduled',
      'cancelled',
      'completed'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'event_visibility') then
    create type public.event_visibility as enum (
      'club',
      'team',
      'private'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'rsvp_status') then
    create type public.rsvp_status as enum (
      'pending',
      'present',
      'absent',
      'maybe',
      'seen_no_reply'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'attendance_status') then
    create type public.attendance_status as enum (
      'present',
      'absent',
      'late',
      'excused'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'announcement_priority') then
    create type public.announcement_priority as enum (
      'normal',
      'important',
      'urgent',
      'administrative'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'document_type') then
    create type public.document_type as enum (
      'medical_certificate',
      'identity_document',
      'registration_form',
      'waiver',
      'insurance',
      'payment_receipt',
      'other'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'document_status') then
    create type public.document_status as enum (
      'missing',
      'pending_review',
      'valid',
      'expiring',
      'expired',
      'rejected'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'fee_assignment_status') then
    create type public.fee_assignment_status as enum (
      'due',
      'paid',
      'partial',
      'overdue',
      'cancelled'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'notification_type') then
    create type public.notification_type as enum (
      'new_callup',
      'event_updated',
      'event_cancelled',
      'event_reminder',
      'new_announcement',
      'document_expiring',
      'fee_due',
      'fee_overdue',
      'invitation_received',
      'rsvp_request',
      'account',
      'security'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'content_report_status') then
    create type public.content_report_status as enum (
      'open',
      'reviewing',
      'resolved',
      'dismissed'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'account_deletion_status') then
    create type public.account_deletion_status as enum (
      'requested',
      'processing',
      'completed',
      'cancelled',
      'rejected'
    );
  end if;
end $$;

-- =========================================================
-- UPDATED_AT TRIGGER
-- =========================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =========================================================
-- TABLES
-- =========================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  first_name text,
  last_name text,
  phone text,
  avatar_url text,
  email_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.clubs (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete restrict,
  name text not null,
  logo_url text,
  sport_primary text not null,
  city text not null,
  address text,
  email text,
  phone text,
  website text,
  fiscal_code text,
  season text,
  subscription_plan public.subscription_plan not null default 'free',
  subscription_status public.subscription_status not null default 'trialing',
  primary_color text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.club_memberships (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.club_role not null,
  status public.membership_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (club_id, user_id)
);

create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  name text not null,
  sport text not null,
  category text,
  season text,
  birth_year integer,
  gender public.team_gender not null default 'unspecified',
  color text,
  training_location text,
  head_coach_user_id uuid references auth.users(id) on delete set null,
  assistant_coach_user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.team_memberships (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  athlete_profile_id uuid,
  role public.club_role not null,
  status public.membership_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (team_id, user_id, role),
  unique (team_id, athlete_profile_id, role)
);

create table if not exists public.athlete_profiles (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  team_id uuid references public.teams(id) on delete set null,
  first_name text not null,
  last_name text not null,
  date_of_birth date,
  jersey_number text,
  sport_role text,
  active boolean not null default true,
  medical_certificate_status public.document_status not null default 'missing',
  medical_certificate_expiry date,
  staff_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table public.team_memberships
  drop constraint if exists team_memberships_athlete_profile_id_fkey;

alter table public.team_memberships
  add constraint team_memberships_athlete_profile_id_fkey
  foreign key (athlete_profile_id)
  references public.athlete_profiles(id)
  on delete cascade;

create table if not exists public.parent_athlete_relations (
  id uuid primary key default gen_random_uuid(),
  parent_user_id uuid not null references auth.users(id) on delete cascade,
  athlete_profile_id uuid not null references public.athlete_profiles(id) on delete cascade,
  relation_type text not null default 'parent',
  verified boolean not null default false,
  created_at timestamptz not null default now(),
  unique (parent_user_id, athlete_profile_id)
);

create table if not exists public.invitations (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  team_id uuid references public.teams(id) on delete cascade,
  athlete_profile_id uuid references public.athlete_profiles(id) on delete set null,
  email text not null,
  role public.club_role not null,
  token text not null unique,
  status public.invitation_status not null default 'sent',
  expires_at timestamptz not null,
  invited_by uuid not null references auth.users(id) on delete restrict,
  accepted_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  team_id uuid references public.teams(id) on delete cascade,
  type public.event_type not null,
  title text not null,
  description text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  location_name text,
  address text,
  created_by uuid not null references auth.users(id) on delete restrict,
  require_rsvp boolean not null default false,
  visibility public.event_visibility not null default 'team',
  status public.event_status not null default 'scheduled',
  notify_members boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint events_end_after_start check (ends_at is null or ends_at >= starts_at)
);

create table if not exists public.event_callups (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  athlete_profile_id uuid not null references public.athlete_profiles(id) on delete cascade,
  sent_by uuid not null references auth.users(id) on delete restrict,
  sent_at timestamptz not null default now(),
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  unique (event_id, athlete_profile_id)
);

create table if not exists public.event_rsvps (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  athlete_profile_id uuid references public.athlete_profiles(id) on delete cascade,
  status public.rsvp_status not null default 'pending',
  note text,
  responded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (event_id, user_id, athlete_profile_id)
);

create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  athlete_profile_id uuid not null references public.athlete_profiles(id) on delete cascade,
  status public.attendance_status not null,
  note text,
  marked_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (event_id, athlete_profile_id)
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  team_id uuid references public.teams(id) on delete cascade,
  title text not null,
  body text not null,
  attachment_path text,
  priority public.announcement_priority not null default 'normal',
  created_by uuid not null references auth.users(id) on delete restrict,
  comments_enabled boolean not null default false,
  read_confirmation_required boolean not null default false,
  pinned boolean not null default false,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.announcement_reads (
  id uuid primary key default gen_random_uuid(),
  announcement_id uuid not null references public.announcements(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  read_at timestamptz not null default now(),
  unique (announcement_id, user_id)
);

create table if not exists public.announcement_comments (
  id uuid primary key default gen_random_uuid(),
  announcement_id uuid not null references public.announcements(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  hidden_at timestamptz,
  hidden_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  athlete_profile_id uuid references public.athlete_profiles(id) on delete cascade,
  type public.document_type not null,
  status public.document_status not null default 'missing',
  expiry_date date,
  file_path text,
  notes_private text,
  uploaded_by uuid references auth.users(id) on delete set null,
  validated_by uuid references auth.users(id) on delete set null,
  validated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.fees (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  team_id uuid references public.teams(id) on delete cascade,
  title text not null,
  description text,
  amount numeric(10,2) not null check (amount >= 0),
  due_date date not null,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.fee_assignments (
  id uuid primary key default gen_random_uuid(),
  fee_id uuid not null references public.fees(id) on delete cascade,
  athlete_profile_id uuid not null references public.athlete_profiles(id) on delete cascade,
  status public.fee_assignment_status not null default 'due',
  amount_due numeric(10,2) not null check (amount_due >= 0),
  amount_paid numeric(10,2) not null default 0 check (amount_paid >= 0),
  payment_method text,
  paid_at timestamptz,
  receipt_path text,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (fee_id, athlete_profile_id)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  club_id uuid references public.clubs(id) on delete cascade,
  type public.notification_type not null,
  title text not null,
  body text not null,
  deep_link text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('ios', 'android')),
  device_id text,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notification_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  club_id uuid references public.clubs(id) on delete cascade,
  events_enabled boolean not null default true,
  communications_enabled boolean not null default true,
  reminders_enabled boolean not null default true,
  administrative_enabled boolean not null default true,
  quiet_hours_enabled boolean not null default false,
  quiet_hours_start time,
  quiet_hours_end time,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, club_id)
);

create table if not exists public.content_reports (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  reporter_user_id uuid not null references auth.users(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  reason text not null,
  details text,
  status public.content_report_status not null default 'open',
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  club_id uuid references public.clubs(id) on delete cascade,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  status public.account_deletion_status not null default 'requested',
  reason text,
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  processor_notes text
);

-- =========================================================
-- INDEXES
-- =========================================================

create index if not exists profiles_email_idx on public.profiles (email);

create index if not exists clubs_owner_user_id_idx on public.clubs (owner_user_id);
create index if not exists club_memberships_user_id_idx on public.club_memberships (user_id);
create index if not exists club_memberships_club_id_idx on public.club_memberships (club_id);

create index if not exists teams_club_id_idx on public.teams (club_id);
create index if not exists team_memberships_team_id_idx on public.team_memberships (team_id);
create index if not exists team_memberships_user_id_idx on public.team_memberships (user_id);
create index if not exists team_memberships_athlete_profile_id_idx on public.team_memberships (athlete_profile_id);

create index if not exists athlete_profiles_club_id_idx on public.athlete_profiles (club_id);
create index if not exists athlete_profiles_team_id_idx on public.athlete_profiles (team_id);
create index if not exists athlete_profiles_user_id_idx on public.athlete_profiles (user_id);

create index if not exists parent_athlete_relations_parent_user_id_idx on public.parent_athlete_relations (parent_user_id);
create index if not exists parent_athlete_relations_athlete_profile_id_idx on public.parent_athlete_relations (athlete_profile_id);

create index if not exists invitations_club_id_idx on public.invitations (club_id);
create index if not exists invitations_email_idx on public.invitations (email);
create index if not exists invitations_token_idx on public.invitations (token);

create index if not exists events_club_id_idx on public.events (club_id);
create index if not exists events_team_id_idx on public.events (team_id);
create index if not exists events_starts_at_idx on public.events (starts_at);

create index if not exists event_callups_event_id_idx on public.event_callups (event_id);
create index if not exists event_callups_athlete_profile_id_idx on public.event_callups (athlete_profile_id);

create index if not exists event_rsvps_event_id_idx on public.event_rsvps (event_id);
create index if not exists event_rsvps_user_id_idx on public.event_rsvps (user_id);
create index if not exists event_rsvps_athlete_profile_id_idx on public.event_rsvps (athlete_profile_id);

create index if not exists attendance_event_id_idx on public.attendance (event_id);
create index if not exists attendance_athlete_profile_id_idx on public.attendance (athlete_profile_id);

create index if not exists announcements_club_id_idx on public.announcements (club_id);
create index if not exists announcements_team_id_idx on public.announcements (team_id);

create index if not exists documents_club_id_idx on public.documents (club_id);
create index if not exists documents_athlete_profile_id_idx on public.documents (athlete_profile_id);
create index if not exists documents_expiry_date_idx on public.documents (expiry_date);

create index if not exists fees_club_id_idx on public.fees (club_id);
create index if not exists fee_assignments_fee_id_idx on public.fee_assignments (fee_id);
create index if not exists fee_assignments_athlete_profile_id_idx on public.fee_assignments (athlete_profile_id);

create index if not exists notifications_user_id_idx on public.notifications (user_id);
create index if not exists push_tokens_user_id_idx on public.push_tokens (user_id);

create index if not exists audit_logs_club_id_idx on public.audit_logs (club_id);
create index if not exists audit_logs_actor_user_id_idx on public.audit_logs (actor_user_id);

-- =========================================================
-- UPDATED_AT TRIGGERS
-- =========================================================

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists clubs_set_updated_at on public.clubs;
create trigger clubs_set_updated_at
before update on public.clubs
for each row execute function public.set_updated_at();

drop trigger if exists club_memberships_set_updated_at on public.club_memberships;
create trigger club_memberships_set_updated_at
before update on public.club_memberships
for each row execute function public.set_updated_at();

drop trigger if exists teams_set_updated_at on public.teams;
create trigger teams_set_updated_at
before update on public.teams
for each row execute function public.set_updated_at();

drop trigger if exists team_memberships_set_updated_at on public.team_memberships;
create trigger team_memberships_set_updated_at
before update on public.team_memberships
for each row execute function public.set_updated_at();

drop trigger if exists athlete_profiles_set_updated_at on public.athlete_profiles;
create trigger athlete_profiles_set_updated_at
before update on public.athlete_profiles
for each row execute function public.set_updated_at();

drop trigger if exists invitations_set_updated_at on public.invitations;
create trigger invitations_set_updated_at
before update on public.invitations
for each row execute function public.set_updated_at();

drop trigger if exists events_set_updated_at on public.events;
create trigger events_set_updated_at
before update on public.events
for each row execute function public.set_updated_at();

drop trigger if exists event_rsvps_set_updated_at on public.event_rsvps;
create trigger event_rsvps_set_updated_at
before update on public.event_rsvps
for each row execute function public.set_updated_at();

drop trigger if exists attendance_set_updated_at on public.attendance;
create trigger attendance_set_updated_at
before update on public.attendance
for each row execute function public.set_updated_at();

drop trigger if exists announcements_set_updated_at on public.announcements;
create trigger announcements_set_updated_at
before update on public.announcements
for each row execute function public.set_updated_at();

drop trigger if exists announcement_comments_set_updated_at on public.announcement_comments;
create trigger announcement_comments_set_updated_at
before update on public.announcement_comments
for each row execute function public.set_updated_at();

drop trigger if exists documents_set_updated_at on public.documents;
create trigger documents_set_updated_at
before update on public.documents
for each row execute function public.set_updated_at();

drop trigger if exists fees_set_updated_at on public.fees;
create trigger fees_set_updated_at
before update on public.fees
for each row execute function public.set_updated_at();

drop trigger if exists fee_assignments_set_updated_at on public.fee_assignments;
create trigger fee_assignments_set_updated_at
before update on public.fee_assignments
for each row execute function public.set_updated_at();

drop trigger if exists push_tokens_set_updated_at on public.push_tokens;
create trigger push_tokens_set_updated_at
before update on public.push_tokens
for each row execute function public.set_updated_at();

drop trigger if exists notification_preferences_set_updated_at on public.notification_preferences;
create trigger notification_preferences_set_updated_at
before update on public.notification_preferences
for each row execute function public.set_updated_at();

drop trigger if exists content_reports_set_updated_at on public.content_reports;
create trigger content_reports_set_updated_at
before update on public.content_reports
for each row execute function public.set_updated_at();

-- =========================================================
-- AUTH PROFILE TRIGGER
-- =========================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    first_name,
    last_name,
    email_verified
  )
  values (
    new.id,
    coalesce(new.email, ''),
    nullif(new.raw_user_meta_data ->> 'first_name', ''),
    nullif(new.raw_user_meta_data ->> 'last_name', ''),
    coalesce(new.email_confirmed_at is not null, false)
  )
  on conflict (id) do update
  set
    email = excluded.email,
    email_verified = excluded.email_verified,
    updated_at = now();

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Supabase warns that profile triggers should be tested carefully,
-- because a failing trigger can block user signups.

-- =========================================================
-- CLUB OWNER MEMBERSHIP TRIGGER
-- =========================================================

create or replace function public.handle_new_club()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.club_memberships (
    club_id,
    user_id,
    role,
    status
  )
  values (
    new.id,
    new.owner_user_id,
    'owner',
    'active'
  )
  on conflict (club_id, user_id) do update
  set
    role = 'owner',
    status = 'active',
    updated_at = now();

  return new;
end;
$$;

drop trigger if exists on_club_created on public.clubs;

create trigger on_club_created
after insert on public.clubs
for each row execute function public.handle_new_club();

-- =========================================================
-- SECURITY HELPER FUNCTIONS
-- =========================================================

create or replace function public.current_user_id()
returns uuid
language sql
stable
as $$
  select auth.uid();
$$;

create or replace function public.is_club_member(target_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.club_memberships cm
    where cm.club_id = target_club_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  );
$$;

create or replace function public.has_club_role(
  target_club_id uuid,
  allowed_roles public.club_role[]
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.club_memberships cm
    where cm.club_id = target_club_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role = any(allowed_roles)
  );
$$;

create or replace function public.is_team_member(target_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.team_memberships tm
    where tm.team_id = target_team_id
      and tm.user_id = auth.uid()
      and tm.status = 'active'
  );
$$;

create or replace function public.can_manage_team(target_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.teams t
    where t.id = target_team_id
      and (
        public.has_club_role(
          t.club_id,
          array['owner', 'admin', 'team_manager']::public.club_role[]
        )
        or exists (
          select 1
          from public.team_memberships tm
          where tm.team_id = target_team_id
            and tm.user_id = auth.uid()
            and tm.status = 'active'
            and tm.role in ('coach', 'team_manager')
        )
      )
  );
$$;

create or replace function public.is_parent_of_athlete(target_athlete_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.parent_athlete_relations par
    where par.athlete_profile_id = target_athlete_profile_id
      and par.parent_user_id = auth.uid()
      and par.verified = true
  );
$$;

create or replace function public.can_view_athlete(target_athlete_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.athlete_profiles ap
    where ap.id = target_athlete_profile_id
      and (
        ap.user_id = auth.uid()
        or public.is_parent_of_athlete(ap.id)
        or public.has_club_role(
          ap.club_id,
          array['owner', 'admin', 'team_manager', 'staff']::public.club_role[]
        )
        or (
          ap.team_id is not null
          and public.can_manage_team(ap.team_id)
        )
      )
  );
$$;

-- =========================================================
-- ENABLE RLS
-- =========================================================

alter table public.profiles enable row level security;
alter table public.clubs enable row level security;
alter table public.club_memberships enable row level security;
alter table public.teams enable row level security;
alter table public.team_memberships enable row level security;
alter table public.athlete_profiles enable row level security;
alter table public.parent_athlete_relations enable row level security;
alter table public.invitations enable row level security;
alter table public.events enable row level security;
alter table public.event_callups enable row level security;
alter table public.event_rsvps enable row level security;
alter table public.attendance enable row level security;
alter table public.announcements enable row level security;
alter table public.announcement_reads enable row level security;
alter table public.announcement_comments enable row level security;
alter table public.documents enable row level security;
alter table public.fees enable row level security;
alter table public.fee_assignments enable row level security;
alter table public.notifications enable row level security;
alter table public.push_tokens enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.content_reports enable row level security;
alter table public.audit_logs enable row level security;
alter table public.account_deletion_requests enable row level security;

-- =========================================================
-- RLS POLICIES
-- =========================================================

drop policy if exists "profiles_select_own_or_same_club" on public.profiles;
create policy "profiles_select_own_or_same_club"
on public.profiles
for select
to authenticated
using (
  id = auth.uid()
  or exists (
    select 1
    from public.club_memberships my_cm
    join public.club_memberships other_cm
      on other_cm.club_id = my_cm.club_id
    where my_cm.user_id = auth.uid()
      and my_cm.status = 'active'
      and other_cm.user_id = profiles.id
      and other_cm.status = 'active'
  )
);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "clubs_select_members" on public.clubs;
create policy "clubs_select_members"
on public.clubs
for select
to authenticated
using (public.is_club_member(id));

drop policy if exists "clubs_insert_authenticated_owner" on public.clubs;
create policy "clubs_insert_authenticated_owner"
on public.clubs
for insert
to authenticated
with check (owner_user_id = auth.uid());

drop policy if exists "clubs_update_admins" on public.clubs;
create policy "clubs_update_admins"
on public.clubs
for update
to authenticated
using (
  public.has_club_role(id, array['owner', 'admin']::public.club_role[])
)
with check (
  public.has_club_role(id, array['owner', 'admin']::public.club_role[])
);

drop policy if exists "club_memberships_select_club_members" on public.club_memberships;
create policy "club_memberships_select_club_members"
on public.club_memberships
for select
to authenticated
using (public.is_club_member(club_id));

drop policy if exists "club_memberships_manage_admins" on public.club_memberships;
create policy "club_memberships_manage_admins"
on public.club_memberships
for all
to authenticated
using (
  public.has_club_role(club_id, array['owner', 'admin']::public.club_role[])
)
with check (
  public.has_club_role(club_id, array['owner', 'admin']::public.club_role[])
);

drop policy if exists "teams_select_club_members" on public.teams;
create policy "teams_select_club_members"
on public.teams
for select
to authenticated
using (public.is_club_member(club_id));

drop policy if exists "teams_manage_admins_managers" on public.teams;
create policy "teams_manage_admins_managers"
on public.teams
for all
to authenticated
using (
  public.has_club_role(club_id, array['owner', 'admin', 'team_manager']::public.club_role[])
)
with check (
  public.has_club_role(club_id, array['owner', 'admin', 'team_manager']::public.club_role[])
);

drop policy if exists "team_memberships_select_club_members" on public.team_memberships;
create policy "team_memberships_select_club_members"
on public.team_memberships
for select
to authenticated
using (
  exists (
    select 1
    from public.teams t
    where t.id = team_memberships.team_id
      and public.is_club_member(t.club_id)
  )
);

drop policy if exists "team_memberships_manage_team_managers" on public.team_memberships;
create policy "team_memberships_manage_team_managers"
on public.team_memberships
for all
to authenticated
using (public.can_manage_team(team_id))
with check (public.can_manage_team(team_id));

drop policy if exists "athlete_profiles_select_authorized" on public.athlete_profiles;
create policy "athlete_profiles_select_authorized"
on public.athlete_profiles
for select
to authenticated
using (public.can_view_athlete(id));

drop policy if exists "athlete_profiles_manage_staff" on public.athlete_profiles;
create policy "athlete_profiles_manage_staff"
on public.athlete_profiles
for all
to authenticated
using (
  public.has_club_role(
    club_id,
    array['owner', 'admin', 'team_manager', 'staff']::public.club_role[]
  )
  or (
    team_id is not null
    and public.can_manage_team(team_id)
  )
)
with check (
  public.has_club_role(
    club_id,
    array['owner', 'admin', 'team_manager', 'staff']::public.club_role[]
  )
  or (
    team_id is not null
    and public.can_manage_team(team_id)
  )
);

drop policy if exists "parent_athlete_relations_select_authorized" on public.parent_athlete_relations;
create policy "parent_athlete_relations_select_authorized"
on public.parent_athlete_relations
for select
to authenticated
using (
  parent_user_id = auth.uid()
  or public.can_view_athlete(athlete_profile_id)
);

drop policy if exists "parent_athlete_relations_manage_admins" on public.parent_athlete_relations;
create policy "parent_athlete_relations_manage_admins"
on public.parent_athlete_relations
for all
to authenticated
using (
  exists (
    select 1
    from public.athlete_profiles ap
    where ap.id = parent_athlete_relations.athlete_profile_id
      and public.has_club_role(
        ap.club_id,
        array['owner', 'admin', 'team_manager', 'staff']::public.club_role[]
      )
  )
)
with check (
  exists (
    select 1
    from public.athlete_profiles ap
    where ap.id = parent_athlete_relations.athlete_profile_id
      and public.has_club_role(
        ap.club_id,
        array['owner', 'admin', 'team_manager', 'staff']::public.club_role[]
      )
  )
);

drop policy if exists "invitations_select_authorized" on public.invitations;
create policy "invitations_select_authorized"
on public.invitations
for select
to authenticated
using (
  public.has_club_role(
    club_id,
    array['owner', 'admin', 'team_manager', 'coach']::public.club_role[]
  )
  or lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
);

drop policy if exists "invitations_manage_staff" on public.invitations;
create policy "invitations_manage_staff"
on public.invitations
for all
to authenticated
using (
  public.has_club_role(
    club_id,
    array['owner', 'admin', 'team_manager', 'coach']::public.club_role[]
  )
)
with check (
  public.has_club_role(
    club_id,
    array['owner', 'admin', 'team_manager', 'coach']::public.club_role[]
  )
);

drop policy if exists "events_select_club_members" on public.events;
create policy "events_select_club_members"
on public.events
for select
to authenticated
using (
  public.is_club_member(club_id)
  and (
    visibility = 'club'
    or team_id is null
    or public.is_team_member(team_id)
    or public.can_manage_team(team_id)
  )
);

drop policy if exists "events_manage_authorized" on public.events;
create policy "events_manage_authorized"
on public.events
for all
to authenticated
using (
  public.has_club_role(
    club_id,
    array['owner', 'admin', 'team_manager']::public.club_role[]
  )
  or (
    team_id is not null
    and public.can_manage_team(team_id)
  )
)
with check (
  created_by = auth.uid()
  and (
    public.has_club_role(
      club_id,
      array['owner', 'admin', 'team_manager']::public.club_role[]
    )
    or (
      team_id is not null
      and public.can_manage_team(team_id)
    )
  )
);

drop policy if exists "event_callups_select_authorized" on public.event_callups;
create policy "event_callups_select_authorized"
on public.event_callups
for select
to authenticated
using (
  exists (
    select 1
    from public.events e
    where e.id = event_callups.event_id
      and public.is_club_member(e.club_id)
  )
  and public.can_view_athlete(athlete_profile_id)
);

drop policy if exists "event_callups_manage_team_staff" on public.event_callups;
create policy "event_callups_manage_team_staff"
on public.event_callups
for all
to authenticated
using (
  exists (
    select 1
    from public.events e
    where e.id = event_callups.event_id
      and (
        public.has_club_role(
          e.club_id,
          array['owner', 'admin', 'team_manager']::public.club_role[]
        )
        or (
          e.team_id is not null
          and public.can_manage_team(e.team_id)
        )
      )
  )
)
with check (
  sent_by = auth.uid()
  and exists (
    select 1
    from public.events e
    where e.id = event_callups.event_id
      and (
        public.has_club_role(
          e.club_id,
          array['owner', 'admin', 'team_manager']::public.club_role[]
        )
        or (
          e.team_id is not null
          and public.can_manage_team(e.team_id)
        )
      )
  )
);

drop policy if exists "event_rsvps_select_authorized" on public.event_rsvps;
create policy "event_rsvps_select_authorized"
on public.event_rsvps
for select
to authenticated
using (
  user_id = auth.uid()
  or (
    athlete_profile_id is not null
    and public.can_view_athlete(athlete_profile_id)
  )
  or exists (
    select 1
    from public.events e
    where e.id = event_rsvps.event_id
      and (
        public.has_club_role(
          e.club_id,
          array['owner', 'admin', 'team_manager']::public.club_role[]
        )
        or (
          e.team_id is not null
          and public.can_manage_team(e.team_id)
        )
      )
  )
);

drop policy if exists "event_rsvps_insert_own_or_parent" on public.event_rsvps;
create policy "event_rsvps_insert_own_or_parent"
on public.event_rsvps
for insert
to authenticated
with check (
  user_id = auth.uid()
  and (
    athlete_profile_id is null
    or public.can_view_athlete(athlete_profile_id)
  )
);

drop policy if exists "event_rsvps_update_own_or_staff" on public.event_rsvps;
create policy "event_rsvps_update_own_or_staff"
on public.event_rsvps
for update
to authenticated
using (
  user_id = auth.uid()
  or exists (
    select 1
    from public.events e
    where e.id = event_rsvps.event_id
      and (
        public.has_club_role(
          e.club_id,
          array['owner', 'admin', 'team_manager']::public.club_role[]
        )
        or (
          e.team_id is not null
          and public.can_manage_team(e.team_id)
        )
      )
  )
)
with check (
  user_id = auth.uid()
  or exists (
    select 1
    from public.events e
    where e.id = event_rsvps.event_id
      and (
        public.has_club_role(
          e.club_id,
          array['owner', 'admin', 'team_manager']::public.club_role[]
        )
        or (
          e.team_id is not null
          and public.can_manage_team(e.team_id)
        )
      )
  )
);

drop policy if exists "attendance_select_authorized" on public.attendance;
create policy "attendance_select_authorized"
on public.attendance
for select
to authenticated
using (
  public.can_view_athlete(athlete_profile_id)
  or exists (
    select 1
    from public.events e
    where e.id = attendance.event_id
      and (
        public.has_club_role(
          e.club_id,
          array['owner', 'admin', 'team_manager']::public.club_role[]
        )
        or (
          e.team_id is not null
          and public.can_manage_team(e.team_id)
        )
      )
  )
);

drop policy if exists "attendance_manage_staff" on public.attendance;
create policy "attendance_manage_staff"
on public.attendance
for all
to authenticated
using (
  exists (
    select 1
    from public.events e
    where e.id = attendance.event_id
      and (
        public.has_club_role(
          e.club_id,
          array['owner', 'admin', 'team_manager']::public.club_role[]
        )
        or (
          e.team_id is not null
          and public.can_manage_team(e.team_id)
        )
      )
  )
)
with check (
  marked_by = auth.uid()
  and exists (
    select 1
    from public.events e
    where e.id = attendance.event_id
      and (
        public.has_club_role(
          e.club_id,
          array['owner', 'admin', 'team_manager']::public.club_role[]
        )
        or (
          e.team_id is not null
          and public.can_manage_team(e.team_id)
        )
      )
  )
);

drop policy if exists "announcements_select_targets" on public.announcements;
create policy "announcements_select_targets"
on public.announcements
for select
to authenticated
using (
  public.is_club_member(club_id)
  and (
    team_id is null
    or public.is_team_member(team_id)
    or public.can_manage_team(team_id)
  )
);

drop policy if exists "announcements_manage_staff" on public.announcements;
create policy "announcements_manage_staff"
on public.announcements
for all
to authenticated
using (
  public.has_club_role(
    club_id,
    array['owner', 'admin', 'team_manager']::public.club_role[]
  )
  or (
    team_id is not null
    and public.can_manage_team(team_id)
  )
)
with check (
  created_by = auth.uid()
  and (
    public.has_club_role(
      club_id,
      array['owner', 'admin', 'team_manager']::public.club_role[]
    )
    or (
      team_id is not null
      and public.can_manage_team(team_id)
    )
  )
);

drop policy if exists "announcement_reads_manage_own" on public.announcement_reads;
create policy "announcement_reads_manage_own"
on public.announcement_reads
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "announcement_comments_select_members" on public.announcement_comments;
create policy "announcement_comments_select_members"
on public.announcement_comments
for select
to authenticated
using (
  exists (
    select 1
    from public.announcements a
    where a.id = announcement_comments.announcement_id
      and public.is_club_member(a.club_id)
      and a.deleted_at is null
  )
);

drop policy if exists "announcement_comments_insert_members" on public.announcement_comments;
create policy "announcement_comments_insert_members"
on public.announcement_comments
for insert
to authenticated
with check (
  user_id = auth.uid()
  and exists (
    select 1
    from public.announcements a
    where a.id = announcement_comments.announcement_id
      and a.comments_enabled = true
      and public.is_club_member(a.club_id)
      and a.deleted_at is null
  )
);

drop policy if exists "announcement_comments_update_own" on public.announcement_comments;
create policy "announcement_comments_update_own"
on public.announcement_comments
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "documents_select_authorized" on public.documents;
create policy "documents_select_authorized"
on public.documents
for select
to authenticated
using (
  public.has_club_role(
    club_id,
    array['owner', 'admin', 'team_manager', 'staff']::public.club_role[]
  )
  or (
    athlete_profile_id is not null
    and public.can_view_athlete(athlete_profile_id)
  )
);

drop policy if exists "documents_manage_authorized" on public.documents;
create policy "documents_manage_authorized"
on public.documents
for all
to authenticated
using (
  public.has_club_role(
    club_id,
    array['owner', 'admin', 'team_manager', 'staff']::public.club_role[]
  )
  or (
    athlete_profile_id is not null
    and public.is_parent_of_athlete(athlete_profile_id)
  )
)
with check (
  public.has_club_role(
    club_id,
    array['owner', 'admin', 'team_manager', 'staff']::public.club_role[]
  )
  or (
    athlete_profile_id is not null
    and public.is_parent_of_athlete(athlete_profile_id)
  )
);

drop policy if exists "fees_select_club_members" on public.fees;
create policy "fees_select_club_members"
on public.fees
for select
to authenticated
using (public.is_club_member(club_id));

drop policy if exists "fees_manage_admins" on public.fees;
create policy "fees_manage_admins"
on public.fees
for all
to authenticated
using (
  public.has_club_role(
    club_id,
    array['owner', 'admin', 'team_manager']::public.club_role[]
  )
)
with check (
  public.has_club_role(
    club_id,
    array['owner', 'admin', 'team_manager']::public.club_role[]
  )
);

drop policy if exists "fee_assignments_select_authorized" on public.fee_assignments;
create policy "fee_assignments_select_authorized"
on public.fee_assignments
for select
to authenticated
using (
  public.can_view_athlete(athlete_profile_id)
  or exists (
    select 1
    from public.fees f
    where f.id = fee_assignments.fee_id
      and public.has_club_role(
        f.club_id,
        array['owner', 'admin', 'team_manager']::public.club_role[]
      )
  )
);

drop policy if exists "fee_assignments_manage_admins" on public.fee_assignments;
create policy "fee_assignments_manage_admins"
on public.fee_assignments
for all
to authenticated
using (
  exists (
    select 1
    from public.fees f
    where f.id = fee_assignments.fee_id
      and public.has_club_role(
        f.club_id,
        array['owner', 'admin', 'team_manager']::public.club_role[]
      )
  )
)
with check (
  exists (
    select 1
    from public.fees f
    where f.id = fee_assignments.fee_id
      and public.has_club_role(
        f.club_id,
        array['owner', 'admin', 'team_manager']::public.club_role[]
      )
  )
);

drop policy if exists "notifications_manage_own" on public.notifications;
create policy "notifications_manage_own"
on public.notifications
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "push_tokens_manage_own" on public.push_tokens;
create policy "push_tokens_manage_own"
on public.push_tokens
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "notification_preferences_manage_own" on public.notification_preferences;
create policy "notification_preferences_manage_own"
on public.notification_preferences
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "content_reports_insert_members" on public.content_reports;
create policy "content_reports_insert_members"
on public.content_reports
for insert
to authenticated
with check (
  reporter_user_id = auth.uid()
  and public.is_club_member(club_id)
);

drop policy if exists "content_reports_select_own_or_admin" on public.content_reports;
create policy "content_reports_select_own_or_admin"
on public.content_reports
for select
to authenticated
using (
  reporter_user_id = auth.uid()
  or public.has_club_role(
    club_id,
    array['owner', 'admin']::public.club_role[]
  )
);

drop policy if exists "content_reports_update_admins" on public.content_reports;
create policy "content_reports_update_admins"
on public.content_reports
for update
to authenticated
using (
  public.has_club_role(
    club_id,
    array['owner', 'admin']::public.club_role[]
  )
)
with check (
  public.has_club_role(
    club_id,
    array['owner', 'admin']::public.club_role[]
  )
);

drop policy if exists "audit_logs_select_admins" on public.audit_logs;
create policy "audit_logs_select_admins"
on public.audit_logs
for select
to authenticated
using (
  club_id is not null
  and public.has_club_role(
    club_id,
    array['owner', 'admin']::public.club_role[]
  )
);

drop policy if exists "account_deletion_requests_manage_own" on public.account_deletion_requests;
create policy "account_deletion_requests_manage_own"
on public.account_deletion_requests
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());