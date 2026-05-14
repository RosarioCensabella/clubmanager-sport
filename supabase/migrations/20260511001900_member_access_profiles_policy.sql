-- ClubManager Sport
-- Allow club staff/admin screens to read profiles for members in the same club.
-- Version: 20260511001900

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'profiles'
      and policyname = 'profiles_select_for_club_access_managers'
  ) then
    create policy profiles_select_for_club_access_managers
    on public.profiles
    for select
    to authenticated
    using (
      id = auth.uid()
      or exists (
        select 1
        from public.club_memberships viewer
        join public.club_memberships target
          on target.club_id = viewer.club_id
        where viewer.user_id = auth.uid()
          and viewer.status = 'active'
          and viewer.role in ('owner', 'admin', 'team_manager', 'coach', 'staff')
          and target.user_id = public.profiles.id
          and target.status = 'active'
      )
    );
  end if;
end $$;

notify pgrst, 'reload schema';