-- ClubManager Sport
-- Documents and deadlines hardening
-- Version: 20260511000810

create extension if not exists pgcrypto;

insert into storage.buckets (id, name, public)
values ('club-documents', 'club-documents', false)
on conflict (id) do nothing;

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  team_id uuid references public.teams(id) on delete set null,
  athlete_profile_id uuid references public.athlete_profiles(id) on delete set null,
  title text not null,
  description text,
  category text not null default 'other',
  scope text not null default 'club',
  status text not null default 'active',
  storage_bucket text not null default 'club-documents',
  file_path text not null,
  file_name text not null,
  mime_type text,
  size_bytes bigint,
  expires_at date,
  uploaded_by uuid references auth.users(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table public.documents
add column if not exists team_id uuid references public.teams(id) on delete set null;

alter table public.documents
add column if not exists athlete_profile_id uuid references public.athlete_profiles(id) on delete set null;

alter table public.documents
add column if not exists title text;

alter table public.documents
add column if not exists description text;

alter table public.documents
add column if not exists category text;

alter table public.documents
add column if not exists scope text;

alter table public.documents
add column if not exists status text;

alter table public.documents
add column if not exists storage_bucket text not null default 'club-documents';

alter table public.documents
add column if not exists file_path text;

alter table public.documents
add column if not exists file_name text;

alter table public.documents
add column if not exists mime_type text;

alter table public.documents
add column if not exists size_bytes bigint;

alter table public.documents
add column if not exists expires_at date;

alter table public.documents
add column if not exists uploaded_by uuid references auth.users(id) on delete set null;

alter table public.documents
add column if not exists created_by uuid references auth.users(id) on delete set null;

alter table public.documents
add column if not exists deleted_at timestamptz;

update public.documents
set title = coalesce(title, file_name, 'Documento')
where title is null;

update public.documents
set category = coalesce(category, 'other')
where category is null;

update public.documents
set scope = coalesce(scope, 'club')
where scope is null;

update public.documents
set status = coalesce(status, 'active')
where status is null;

update public.documents
set storage_bucket = coalesce(storage_bucket, 'club-documents')
where storage_bucket is null;

alter table public.documents
drop constraint if exists documents_category_check;

alter table public.documents
add constraint documents_category_check
check (
  category::text in (
    'medical_certificate',
    'identity_document',
    'membership',
    'privacy',
    'payment',
    'other'
  )
);

alter table public.documents
drop constraint if exists documents_scope_check;

alter table public.documents
add constraint documents_scope_check
check (
  scope::text in (
    'club',
    'team',
    'athlete'
  )
);

alter table public.documents
drop constraint if exists documents_status_check;

alter table public.documents
add constraint documents_status_check
check (
  status::text in (
    'active',
    'archived'
  )
);

alter table public.documents enable row level security;

drop trigger if exists documents_set_updated_at on public.documents;

create trigger documents_set_updated_at
before update on public.documents
for each row
execute function public.set_updated_at();

create or replace function public.can_manage_documents(p_club_id uuid)
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
      and cm.role in ('owner', 'admin', 'team_manager', 'coach', 'staff')
  );
$$;

create or replace function public.can_view_document(p_document_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.documents d
    join public.club_memberships cm
      on cm.club_id = d.club_id
    where d.id = p_document_id
      and d.deleted_at is null
      and d.status::text = 'active'
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and (
        d.scope::text = 'club'
        or cm.role in ('owner', 'admin', 'team_manager', 'coach', 'staff')
        or (
          d.scope::text = 'team'
          and d.team_id is not null
          and exists (
            select 1
            from public.team_memberships tm
            join public.athlete_profiles ap
              on ap.id = tm.athlete_profile_id
            where tm.team_id = d.team_id
              and tm.status = 'active'
              and (
                ap.user_id = auth.uid()
                or exists (
                  select 1
                  from public.parent_athlete_relations par
                  where par.athlete_profile_id = ap.id
                    and par.parent_user_id = auth.uid()
                )
              )
          )
        )
        or (
          d.scope::text = 'athlete'
          and d.athlete_profile_id is not null
          and exists (
            select 1
            from public.athlete_profiles ap
            where ap.id = d.athlete_profile_id
              and (
                ap.user_id = auth.uid()
                or exists (
                  select 1
                  from public.parent_athlete_relations par
                  where par.athlete_profile_id = ap.id
                    and par.parent_user_id = auth.uid()
                )
              )
          )
        )
      )
  );
$$;

grant execute on function public.can_manage_documents(uuid) to authenticated;
grant execute on function public.can_view_document(uuid) to authenticated;

drop policy if exists "documents_select_authorized" on public.documents;
drop policy if exists "documents_manage_authorized" on public.documents;
drop policy if exists "documents_insert_authorized" on public.documents;
drop policy if exists "documents_update_authorized" on public.documents;
drop policy if exists "documents_delete_authorized" on public.documents;

create policy "documents_select_authorized"
on public.documents
for select
to authenticated
using (
  public.can_view_document(id)
  or public.can_manage_documents(club_id)
);

create policy "documents_insert_authorized"
on public.documents
for insert
to authenticated
with check (
  public.can_manage_documents(club_id)
);

create policy "documents_update_authorized"
on public.documents
for update
to authenticated
using (
  public.can_manage_documents(club_id)
)
with check (
  public.can_manage_documents(club_id)
);

create policy "documents_delete_authorized"
on public.documents
for delete
to authenticated
using (
  public.can_manage_documents(club_id)
);

drop policy if exists "club_documents_storage_select" on storage.objects;
drop policy if exists "club_documents_storage_insert" on storage.objects;
drop policy if exists "club_documents_storage_update" on storage.objects;
drop policy if exists "club_documents_storage_delete" on storage.objects;

create policy "club_documents_storage_select"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'club-documents'
  and exists (
    select 1
    from public.club_memberships cm
    where cm.club_id = ((storage.foldername(name))[1])::uuid
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  )
);

create policy "club_documents_storage_insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'club-documents'
  and exists (
    select 1
    from public.club_memberships cm
    where cm.club_id = ((storage.foldername(name))[1])::uuid
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('owner', 'admin', 'team_manager', 'coach', 'staff')
  )
);

create policy "club_documents_storage_update"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'club-documents'
  and exists (
    select 1
    from public.club_memberships cm
    where cm.club_id = ((storage.foldername(name))[1])::uuid
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('owner', 'admin', 'team_manager', 'coach', 'staff')
  )
)
with check (
  bucket_id = 'club-documents'
  and exists (
    select 1
    from public.club_memberships cm
    where cm.club_id = ((storage.foldername(name))[1])::uuid
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('owner', 'admin', 'team_manager', 'coach', 'staff')
  )
);

create policy "club_documents_storage_delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'club-documents'
  and exists (
    select 1
    from public.club_memberships cm
    where cm.club_id = ((storage.foldername(name))[1])::uuid
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('owner', 'admin', 'team_manager', 'coach', 'staff')
  )
);