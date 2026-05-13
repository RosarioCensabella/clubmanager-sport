import '../../../core/permissions/club_role.dart';

class InvitationAcceptance {
  const InvitationAcceptance({
    required this.id,
    required this.clubId,
    required this.email,
    required this.role,
    required this.status,
    required this.token,
    required this.expiresAt,
    required this.createdAt,
    required this.clubName,
    this.teamId,
    this.teamName,
  });

  final String id;
  final String clubId;
  final String? teamId;
  final String email;
  final ClubRole role;
  final String status;
  final String token;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String clubName;
  final String? teamName;

  factory InvitationAcceptance.fromMap(Map<String, dynamic> map) {
    return InvitationAcceptance(
      id: (map['id'] ?? '').toString(),
      clubId: (map['club_id'] ?? '').toString(),
      teamId: map['team_id']?.toString(),
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
      clubName: (map['club_name'] ?? '').toString(),
      teamName: map['team_name']?.toString(),
    );
  }

  bool get isValid => status == 'sent' && !isExpired;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get roleLabel => role.label;

  String get statusLabel {
    if (isExpired && status == 'sent') {
      return 'Scaduto';
    }

    switch (status) {
      case 'draft':
        return 'Bozza';
      case 'sent':
        return 'Inviato';
      case 'accepted':
        return 'Accettato';
      case 'expired':
        return 'Scaduto';
      case 'revoked':
        return 'Revocato';
      case 'cancelled':
        return 'Annullato';
      default:
        return status;
    }
  }

  String get expiresAtLabel {
    final local = expiresAt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
