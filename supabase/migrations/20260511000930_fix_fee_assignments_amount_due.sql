-- ClubManager Sport
-- Fix fee_assignments legacy amount_due compatibility
-- Version: 20260511000930

do $$
begin
  if to_regclass('public.fee_assignments') is null then
    return;
  end if;

  alter table public.fee_assignments
  add column if not exists amount_due numeric(12, 2);

  update public.fee_assignments
  set amount_due = 0
  where amount_due is null;

  alter table public.fee_assignments
  alter column amount_due set default 0;

  alter table public.fee_assignments
  alter column amount_due set not null;

  alter table public.fee_assignments
  add column if not exists amount_paid numeric(12, 2);

  update public.fee_assignments
  set amount_paid = 0
  where amount_paid is null;

  alter table public.fee_assignments
  alter column amount_paid set default 0;

  alter table public.fee_assignments
  alter column amount_paid set not null;
end $$;

notify pgrst, 'reload schema';