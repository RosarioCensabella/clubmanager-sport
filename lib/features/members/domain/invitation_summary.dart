import '../../../core/permissions/club_role.dart';

class InvitationSummary {
  const InvitationSummary({
    required this.id,
    required this.clubId,
    required this.email,
    required this.role,
    required this.status,
    required this.token,
    required this.expiresAt,
    required this.createdAt,
    required this.emailSendAttempts,
    this.teamId,
    this.teamName,
    this.emailSentAt,
    this.emailLastError,
  });

  final String id;
  final String clubId;
  final String? teamId;
  final String? teamName;
  final String email;
  final ClubRole role;
  final String status;
  final String token;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? emailSentAt;
  final String? emailLastError;
  final int emailSendAttempts;

  factory InvitationSummary.fromMap(Map<String, dynamic> map) {
    final rawTeam = map['teams'];
    final teamMap = rawTeam is Map
        ? Map<String, dynamic>.from(rawTeam)
        : <String, dynamic>{};

    return InvitationSummary(
      id: (map['id'] ?? '').toString(),
      clubId: (map['club_id'] ?? '').toString(),
      teamId: map['team_id']?.toString(),
      teamName: teamMap['name']?.toString(),
      email: (map['email'] ?? '').toString(),
      role: clubRoleFromDatabaseValue(map['role']?.toString()),
      status: (map['status'] ?? '').toString(),
      token: (map['token'] ?? '').toString(),
      expiresAt:
          DateTime.tryParse((map['expires_at'] ?? '').toString()) ??
          DateTime.now(),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
      emailSentAt: DateTime.tryParse((map['email_sent_at'] ?? '').toString()),
      emailLastError: map['email_last_error']?.toString(),
      emailSendAttempts: map['email_send_attempts'] is int
          ? map['email_send_attempts'] as int
          : int.tryParse((map['email_send_attempts'] ?? '0').toString()) ?? 0,
    );
  }

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

  String get emailStatusLabel {
    if (emailSentAt != null) {
      return 'Email inviata';
    }

    if (emailLastError != null && emailLastError!.trim().isNotEmpty) {
      return 'Email non inviata';
    }

    return 'Email da inviare';
  }

  bool get canBeRevoked => status == 'sent';

  bool get canBeDeleted => status == 'revoked';

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get canSendEmail => status == 'sent' && !isExpired;
}
