-- ClubManager Sport
-- Fees hardening
-- Version: 20260511000910

create extension if not exists pgcrypto;

create table if not exists public.fees (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  team_id uuid references public.teams(id) on delete set null,
  title text not null,
  description text,
  scope text not null default 'club',
  amount_cents integer not null default 0,
  currency text not null default 'EUR',
  due_date date,
  status text not null default 'active',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table public.fees
add column if not exists team_id uuid references public.teams(id) on delete set null;

alter table public.fees
add column if not exists description text;

alter table public.fees
add column if not exists scope text;

alter table public.fees
add column if not exists amount_cents integer not null default 0;

alter table public.fees
add column if not exists currency text not null default 'EUR';

alter table public.fees
add column if not exists due_date date;

alter table public.fees
add column if not exists status text;

alter table public.fees
add column if not exists created_by uuid references auth.users(id) on delete set null;

alter table public.fees
add column if not exists deleted_at timestamptz;

update public.fees
set scope = coalesce(scope, 'club')
where scope is null;

update public.fees
set status = coalesce(status, 'active')
where status is null;

update public.fees
set currency = coalesce(currency, 'EUR')
where currency is null;

alter table public.fees
drop constraint if exists fees_scope_check;

alter table public.fees
add constraint fees_scope_check
check (
  scope::text in ('club', 'team', 'athlete')
);

alter table public.fees
drop constraint if exists fees_status_check;

alter table public.fees
add constraint fees_status_check
check (
  status::text in ('active', 'archived')
);

alter table public.fees
drop constraint if exists fees_amount_cents_check;

alter table public.fees
add constraint fees_amount_cents_check
check (amount_cents >= 0);

create table if not exists public.fee_assignments (
  id uuid primary key default gen_random_uuid(),
  fee_id uuid not null references public.fees(id) on delete cascade,
  club_id uuid not null references public.clubs(id) on delete cascade,
  athlete_profile_id uuid not null references public.athlete_profiles(id) on delete cascade,
  amount_cents integer not null default 0,
  currency text not null default 'EUR',
  status text not null default 'unpaid',
  due_date date,
  paid_at timestamptz,
  payment_reference text,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table public.fee_assignments
add column if not exists club_id uuid references public.clubs(id) on delete cascade;

alter table public.fee_assignments
add column if not exists athlete_profile_id uuid references public.athlete_profiles(id) on delete cascade;

alter table public.fee_assignments
add column if not exists amount_cents integer not null default 0;

alter table public.fee_assignments
add column if not exists currency text not null default 'EUR';

alter table public.fee_assignments
add column if not exists status text;

alter table public.fee_assignments
add column if not exists due_date date;

alter table public.fee_assignments
add column if not exists paid_at timestamptz;

alter table public.fee_assignments
add column if not exists payment_reference text;

alter table public.fee_assignments
add column if not exists notes text;

alter table public.fee_assignments
add column if not exists created_by uuid references auth.users(id) on delete set null;

alter table public.fee_assignments
add column if not exists updated_by uuid references auth.users(id) on delete set null;

alter table public.fee_assignments
add column if not exists deleted_at timestamptz;

update public.fee_assignments
set status = coalesce(status, 'unpaid')
where status is null;

update public.fee_assignments
set currency = coalesce(currency, 'EUR')
where currency is null;

alter table public.fee_assignments
drop constraint if exists fee_assignments_status_check;

alter table public.fee_assignments
add constraint fee_assignments_status_check
check (
  status::text in ('unpaid', 'paid', 'partial', 'waived', 'overdue')
);

alter table public.fee_assignments
drop constraint if exists fee_assignments_amount_cents_check;

alter table public.fee_assignments
add constraint fee_assignments_amount_cents_check
check (amount_cents >= 0);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'fee_assignments_fee_athlete_unique'
  ) then
    alter table public.fee_assignments
    add constraint fee_assignments_fee_athlete_unique
    unique (fee_id, athlete_profile_id);
  end if;
end $$;

alter table public.fees enable row level security;
alter table public.fee_assignments enable row level security;

drop trigger if exists fees_set_updated_at on public.fees;
drop trigger if exists fee_assignments_set_updated_at on public.fee_assignments;

create trigger fees_set_updated_at
before update on public.fees
for each row
execute function public.set_updated_at();

create trigger fee_assignments_set_updated_at
before update on public.fee_assignments
for each row
execute function public.set_updated_at();

create or replace function public.can_manage_fees(p_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.club_memberships cm
    where cm.club_id = p_club_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('owner', 'admin', 'team_manager')
  );
$$;

create or replace function public.can_view_fee_assignment(
  p_assignment_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.fee_assignments fa
    join public.club_memberships cm
      on cm.club_id = fa.club_id
    where fa.id = p_assignment_id
      and fa.deleted_at is null
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and (
        cm.role in ('owner', 'admin', 'team_manager', 'coach', 'staff')
        or exists (
          select 1
          from public.athlete_profiles ap
          where ap.id = fa.athlete_profile_id
            and ap.user_id = auth.uid()
        )
        or exists (
          select 1
          from public.parent_athlete_relations par
          where par.athlete_profile_id = fa.athlete_profile_id
            and par.parent_user_id = auth.uid()
        )
      )
  );
$$;

grant execute on function public.can_manage_fees(uuid) to authenticated;
grant execute on function public.can_view_fee_assignment(uuid) to authenticated;

drop policy if exists "fees_select_club_members" on public.fees;
drop policy if exists "fees_manage_admins" on public.fees;
drop policy if exists "fees_select_authorized" on public.fees;
drop policy if exists "fees_insert_authorized" on public.fees;
drop policy if exists "fees_update_authorized" on public.fees;
drop policy if exists "fees_delete_authorized" on public.fees;

create policy "fees_select_authorized"
on public.fees
for select
to authenticated
using (
  exists (
    select 1
    from public.club_memberships cm
    where cm.club_id = fees.club_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  )
);

create policy "fees_insert_authorized"
on public.fees
for insert
to authenticated
with check (
  public.can_manage_fees(club_id)
);

create policy "fees_update_authorized"
on public.fees
for update
to authenticated
using (
  public.can_manage_fees(club_id)
)
with check (
  public.can_manage_fees(club_id)
);

create policy "fees_delete_authorized"
on public.fees
for delete
to authenticated
using (
  public.can_manage_fees(club_id)
);

drop policy if exists "fee_assignments_select_authorized" on public.fee_assignments;
drop policy if exists "fee_assignments_manage_admins" on public.fee_assignments;
drop policy if exists "fee_assignments_insert_authorized" on public.fee_assignments;
drop policy if exists "fee_assignments_update_authorized" on public.fee_assignments;
drop policy if exists "fee_assignments_delete_authorized" on public.fee_assignments;

create policy "fee_assignments_select_authorized"
on public.fee_assignments
for select
to authenticated
using (
  public.can_view_fee_assignment(id)
  or public.can_manage_fees(club_id)
);

create policy "fee_assignments_insert_authorized"
on public.fee_assignments
for insert
to authenticated
with check (
  public.can_manage_fees(club_id)
);

create policy "fee_assignments_update_authorized"
on public.fee_assignments
for update
to authenticated
using (
  public.can_manage_fees(club_id)
)
with check (
  public.can_manage_fees(club_id)
);

create policy "fee_assignments_delete_authorized"
on public.fee_assignments
for delete
to authenticated
using (
  public.can_manage_fees(club_id)
);