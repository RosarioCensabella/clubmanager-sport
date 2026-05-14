import '../../../core/permissions/club_role.dart';

class CreateInvitationRequest {
  const CreateInvitationRequest({
    required this.clubId,
    required this.email,
    required this.role,
    required this.token,
    required this.expiresAt,
    this.teamId,
    this.athleteProfileId,
  });

  final String clubId;
  final String? teamId;
  final String? athleteProfileId;
  final String email;
  final ClubRole role;
  final String token;
  final DateTime expiresAt;

  Map<String, dynamic> toInsertMap({required String invitedBy}) {
    return {
      'club_id': clubId,
      'team_id': _nullableTrim(teamId),
      'athlete_profile_id': _nullableTrim(athleteProfileId),
      'email': email.trim().toLowerCase(),
      'role': role.databaseValue,
      'token': token,
      'status': 'sent',
      'expires_at': expiresAt.toUtc().toIso8601String(),
      'invited_by': invitedBy,
    };
  }

  static String? _nullableTrim(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
