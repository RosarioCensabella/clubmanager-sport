-- ClubManager Sport
-- Fix existing fees.amount compatibility
-- Version: 20260511000920

do $$
begin
  if to_regclass('public.fees') is not null then
    if exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'fees'
        and column_name = 'amount'
    ) then
      update public.fees
      set amount = coalesce(amount, amount_cents::numeric / 100)
      where amount is null;

      alter table public.fees
      alter column amount set default 0;
    end if;
  end if;

  if to_regclass('public.fee_assignments') is not null then
    if exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'fee_assignments'
        and column_name = 'amount'
    ) then
      update public.fee_assignments
      set amount = coalesce(amount, amount_cents::numeric / 100)
      where amount is null;

      alter table public.fee_assignments
      alter column amount set default 0;
    end if;
  end if;
end $$;