class CreateAthleteRequest {
  const CreateAthleteRequest({
    required this.clubId,
    required this.firstName,
    required this.lastName,
    required this.medicalCertificateStatus,
    this.teamId,
    this.dateOfBirth,
    this.jerseyNumber,
    this.sportRole,
    this.medicalCertificateExpiry,
    this.staffNotes,
  });

  final String clubId;
  final String? teamId;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? jerseyNumber;
  final String? sportRole;
  final String medicalCertificateStatus;
  final DateTime? medicalCertificateExpiry;
  final String? staffNotes;

  Map<String, dynamic> toInsertMap() {
    return {
      'club_id': clubId,
      'team_id': _nullableTrim(teamId),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'date_of_birth': _dateToString(dateOfBirth),
      'jersey_number': _nullableTrim(jerseyNumber),
      'sport_role': _nullableTrim(sportRole),
      'active': true,
      'medical_certificate_status': medicalCertificateStatus,
      'medical_certificate_expiry': _dateToString(medicalCertificateExpiry),
      'staff_notes': _nullableTrim(staffNotes),
    };
  }

  static String? _nullableTrim(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  static String? _dateToString(DateTime? value) {
    if (value == null) {
      return null;
    }

    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
