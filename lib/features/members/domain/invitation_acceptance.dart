import '../../../core/permissions/club_role.dart';

class InvitationAcceptance {
  const InvitationAcceptance({
    required this.id,
    required this.token,
    required this.clubId,
    required this.clubName,
    required this.email,
    required this.role,
    required this.status,
    required this.expiresAt,
    required this.isValid,
    this.teamId,
    this.teamName,
    this.athleteProfileId,
    this.athleteName,
  });

  final String id;
  final String token;
  final String clubId;
  final String clubName;
  final String? teamId;
  final String? teamName;
  final String? athleteProfileId;
  final String? athleteName;
  final String email;
  final ClubRole role;
  final String status;
  final DateTime expiresAt;
  final bool isValid;

  factory InvitationAcceptance.fromMap(Map<String, dynamic> map) {
    return InvitationAcceptance(
      id: (map['id'] ?? '').toString(),
      token: (map['token'] ?? '').toString(),
      clubId: (map['club_id'] ?? '').toString(),
      clubName: (map['club_name'] ?? '').toString(),
      teamId: map['team_id']?.toString(),
      teamName: map['team_name']?.toString(),
      athleteProfileId: map['athlete_profile_id']?.toString(),
      athleteName: map['athlete_name']?.toString(),
      email: (map['email'] ?? '').toString(),
      role: clubRoleFromDatabaseValue(map['role']?.toString()),
      status: (map['status'] ?? '').toString(),
      expiresAt:
          DateTime.tryParse((map['expires_at'] ?? '').toString()) ??
          DateTime.now(),
      isValid: map['is_valid'] == true,
    );
  }

  String get roleLabel => role.label;

  String get statusLabel {
    switch (status) {
      case 'sent':
        return 'Inviato';
      case 'accepted':
        return 'Accettato';
      case 'expired':
        return 'Scaduto';
      case 'revoked':
        return 'Revocato';
      default:
        return status;
    }
  }

  String get expiresAtLabel {
    final local = expiresAt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString().padLeft(4, '0');

    return '$day/$month/$year';
  }
}
