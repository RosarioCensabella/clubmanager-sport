-- ClubManager Sport
-- Fix RLS policy for clubs insert returning
-- Version: 20260511000200

drop policy if exists "clubs_select_members" on public.clubs;

create policy "clubs_select_members"
on public.clubs
for select
to authenticated
using (
  owner_user_id = auth.uid()
  or public.is_club_member(id)
);

drop policy if exists "clubs_update_admins" on public.clubs;

create policy "clubs_update_admins"
on public.clubs
for update
to authenticated
using (
  owner_user_id = auth.uid()
  or public.has_club_role(id, array['owner', 'admin']::public.club_role[])
)
with check (
  owner_user_id = auth.uid()
  or public.has_club_role(id, array['owner', 'admin']::public.club_role[])
);