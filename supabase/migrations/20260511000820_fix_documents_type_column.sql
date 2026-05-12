-- ClubManager Sport
-- Fix existing documents.type column compatibility
-- Version: 20260511000820

do $$
declare
  type_type regtype;
begin
  if to_regclass('public.documents') is null then
    return;
  end if;

  select atttypid::regtype
  into type_type
  from pg_attribute
  where attrelid = 'public.documents'::regclass
    and attname = 'type'
    and not attisdropped;

  if type_type is not null and type_type::text <> 'text' then
    execute format('alter type %s add value if not exists %L', type_type, 'medical_certificate');
    execute format('alter type %s add value if not exists %L', type_type, 'identity_document');
    execute format('alter type %s add value if not exists %L', type_type, 'membership');
    execute format('alter type %s add value if not exists %L', type_type, 'privacy');
    execute format('alter type %s add value if not exists %L', type_type, 'payment');
    execute format('alter type %s add value if not exists %L', type_type, 'other');
  end if;
end $$;