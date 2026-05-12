import '../../../core/permissions/club_role.dart';
import 'club_summary.dart';

class ClubMembershipSummary {
  const ClubMembershipSummary({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.role,
    required this.status,
    required this.club,
  });

  final String id;
  final String clubId;
  final String userId;
  final ClubRole role;
  final String status;
  final ClubSummary club;

  bool get isActive => status == 'active';

  factory ClubMembershipSummary.fromMap(Map<String, dynamic> map) {
    final rawClub = map['clubs'];
    final clubMap = rawClub is Map
        ? Map<String, dynamic>.from(rawClub)
        : <String, dynamic>{};

    return ClubMembershipSummary(
      id: (map['id'] ?? '').toString(),
      clubId: (map['club_id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      role: clubRoleFromDatabaseValue(map['role']?.toString()),
      status: (map['status'] ?? '').toString(),
      club: ClubSummary.fromMap(clubMap),
    );
  }
}
