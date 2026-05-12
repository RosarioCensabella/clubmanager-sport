class AttendanceSummary {
  const AttendanceSummary({
    required this.id,
    required this.eventId,
    required this.athleteProfileId,
    required this.status,
    required this.createdAt,
    this.notes,
    this.recordedBy,
    this.recordedAt,
  });

  final String id;
  final String eventId;
  final String athleteProfileId;
  final String status;
  final String? notes;
  final String? recordedBy;
  final DateTime? recordedAt;
  final DateTime createdAt;

  factory AttendanceSummary.fromMap(Map<String, dynamic> map) {
    return AttendanceSummary(
      id: (map['id'] ?? '').toString(),
      eventId: (map['event_id'] ?? '').toString(),
      athleteProfileId: (map['athlete_profile_id'] ?? '').toString(),
      status: (map['status'] ?? 'unknown').toString(),
      notes: map['notes']?.toString(),
      recordedBy: (map['recorded_by'] ?? map['marked_by'])?.toString(),
      recordedAt: DateTime.tryParse((map['recorded_at'] ?? '').toString()),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'present':
        return 'Presente';
      case 'absent':
        return 'Assente';
      case 'late':
        return 'In ritardo';
      case 'excused':
        return 'Giustificato';
      default:
        return 'Da registrare';
    }
  }

  bool get isPresent => status == 'present';

  bool get isAbsent => status == 'absent';

  bool get isLate => status == 'late';

  bool get isExcused => status == 'excused';

  bool get isUnknown => status == 'unknown';
}
