import 'package:flutter/material.dart';

class AthleteSummary {
  const AthleteSummary({
    required this.id,
    required this.clubId,
    required this.firstName,
    required this.lastName,
    required this.active,
    required this.medicalCertificateStatus,
    this.userId,
    this.teamId,
    this.teamName,
    this.dateOfBirth,
    this.jerseyNumber,
    this.sportRole,
    this.medicalCertificateExpiry,
    this.staffNotes,
  });

  final String id;
  final String clubId;
  final String? userId;
  final String? teamId;
  final String? teamName;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? jerseyNumber;
  final String? sportRole;
  final bool active;
  final String medicalCertificateStatus;
  final DateTime? medicalCertificateExpiry;
  final String? staffNotes;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isEmpty ? '' : firstName.characters.first;
    final last = lastName.isEmpty ? '' : lastName.characters.first;

    final value = '$first$last'.trim();

    if (value.isEmpty) {
      return '?';
    }

    return value.toUpperCase();
  }

  String get medicalCertificateStatusLabel {
    switch (medicalCertificateStatus) {
      case 'missing':
        return 'Mancante';
      case 'pending_review':
        return 'In verifica';
      case 'valid':
        return 'Valido';
      case 'expiring':
        return 'In scadenza';
      case 'expired':
        return 'Scaduto';
      case 'rejected':
        return 'Rifiutato';
      default:
        return medicalCertificateStatus;
    }
  }

  factory AthleteSummary.fromMap(Map<String, dynamic> map) {
    final rawTeam = map['teams'];
    final teamMap = rawTeam is Map
        ? Map<String, dynamic>.from(rawTeam)
        : <String, dynamic>{};

    return AthleteSummary(
      id: (map['id'] ?? '').toString(),
      clubId: (map['club_id'] ?? '').toString(),
      userId: map['user_id']?.toString(),
      teamId: map['team_id']?.toString(),
      teamName: teamMap['name']?.toString(),
      firstName: (map['first_name'] ?? '').toString(),
      lastName: (map['last_name'] ?? '').toString(),
      dateOfBirth: DateTime.tryParse((map['date_of_birth'] ?? '').toString()),
      jerseyNumber: map['jersey_number']?.toString(),
      sportRole: map['sport_role']?.toString(),
      active: map['active'] == true,
      medicalCertificateStatus: (map['medical_certificate_status'] ?? 'missing')
          .toString(),
      medicalCertificateExpiry: DateTime.tryParse(
        (map['medical_certificate_expiry'] ?? '').toString(),
      ),
      staffNotes: map['staff_notes']?.toString(),
    );
  }
}
