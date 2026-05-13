-- ClubManager Sport
-- Fees enum values preflight
-- Version: 20260511000900

do $$
declare
  fee_status_type regtype;
  fee_scope_type regtype;
  assignment_status_type regtype;
begin
  if to_regclass('public.fees') is not null then
    select atttypid::regtype
    into fee_status_type
    from pg_attribute
    where attrelid = 'public.fees'::regclass
      and attname = 'status'
      and not attisdropped;

    if fee_status_type is not null and fee_status_type::text <> 'text' then
      execute format('alter type %s add value if not exists %L', fee_status_type, 'active');
      execute format('alter type %s add value if not exists %L', fee_status_type, 'archived');
    end if;

    select atttypid::regtype
    into fee_scope_type
    from pg_attribute
    where attrelid = 'public.fees'::regclass
      and attname = 'scope'
      and not attisdropped;

    if fee_scope_type is not null and fee_scope_type::text <> 'text' then
      execute format('alter type %s add value if not exists %L', fee_scope_type, 'club');
      execute format('alter type %s add value if not exists %L', fee_scope_type, 'team');
      execute format('alter type %s add value if not exists %L', fee_scope_type, 'athlete');
    end if;
  end if;

  if to_regclass('public.fee_assignments') is not null then
    select atttypid::regtype
    into assignment_status_type
    from pg_attribute
    where attrelid = 'public.fee_assignments'::regclass
      and attname = 'status'
      and not attisdropped;

    if assignment_status_type is not null and assignment_status_type::text <> 'text' then
      execute format('alter type %s add value if not exists %L', assignment_status_type, 'unpaid');
      execute format('alter type %s add value if not exists %L', assignment_status_type, 'paid');
      execute format('alter type %s add value if not exists %L', assignment_status_type, 'partial');
      execute format('alter type %s add value if not exists %L', assignment_status_type, 'waived');
      execute format('alter type %s add value if not exists %L', assignment_status_type, 'overdue');
    end if;
  end if;
end $$;