import 'club_detail.dart';
import 'club_membership_summary.dart';

class ClubManagementData {
  const ClubManagementData({required this.club, required this.membership});

  final ClubDetail club;
  final ClubMembershipSummary membership;

  bool get canManageClub => membership.role.isClubAdmin;
}
