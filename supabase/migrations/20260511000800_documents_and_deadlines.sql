-- ClubManager Sport
-- Documents enum values preflight
-- Version: 20260511000800
--
-- This migration only extends existing document enums.
-- Table hardening is done in the next migration.

do $$
declare
  category_type regtype;
  scope_type regtype;
  status_type regtype;
begin
  if to_regclass('public.documents') is null then
    return;
  end if;

  select atttypid::regtype
  into category_type
  from pg_attribute
  where attrelid = 'public.documents'::regclass
    and attname = 'category'
    and not attisdropped;

  if category_type is not null and category_type::text <> 'text' then
    execute format('alter type %s add value if not exists %L', category_type, 'medical_certificate');
    execute format('alter type %s add value if not exists %L', category_type, 'identity_document');
    execute format('alter type %s add value if not exists %L', category_type, 'membership');
    execute format('alter type %s add value if not exists %L', category_type, 'privacy');
    execute format('alter type %s add value if not exists %L', category_type, 'payment');
    execute format('alter type %s add value if not exists %L', category_type, 'other');
  end if;

  select atttypid::regtype
  into scope_type
  from pg_attribute
  where attrelid = 'public.documents'::regclass
    and attname = 'scope'
    and not attisdropped;

  if scope_type is not null and scope_type::text <> 'text' then
    execute format('alter type %s add value if not exists %L', scope_type, 'club');
    execute format('alter type %s add value if not exists %L', scope_type, 'team');
    execute format('alter type %s add value if not exists %L', scope_type, 'athlete');
  end if;

  select atttypid::regtype
  into status_type
  from pg_attribute
  where attrelid = 'public.documents'::regclass
    and attname = 'status'
    and not attisdropped;

  if status_type is not null and status_type::text <> 'text' then
    execute format('alter type %s add value if not exists %L', status_type, 'active');
    execute format('alter type %s add value if not exists %L', status_type, 'archived');
  end if;
end $$;