-- ClubManager Sport
-- Attendance enum values preflight
-- Version: 20260511000600
--
-- This migration only extends the existing attendance_status enum.
-- The table hardening is intentionally done in the next migration, so that
-- newly added enum values are committed before being used as defaults/checks.

do $$
begin
  if to_regtype('public.attendance_status') is not null then
    execute 'alter type public.attendance_status add value if not exists ''unknown''';
    execute 'alter type public.attendance_status add value if not exists ''present''';
    execute 'alter type public.attendance_status add value if not exists ''absent''';
    execute 'alter type public.attendance_status add value if not exists ''late''';
    execute 'alter type public.attendance_status add value if not exists ''excused''';
  end if;
end $$;