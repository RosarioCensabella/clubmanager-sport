import '../../athletes/domain/athlete_summary.dart';

class CallupSummary {
  const CallupSummary({
    required this.id,
    required this.eventId,
    required this.athleteProfileId,
    required this.status,
    required this.createdAt,
    required this.athlete,
    this.notes,
    this.responseNote,
    this.respondedBy,
    this.respondedAt,
  });

  final String id;
  final String eventId;
  final String athleteProfileId;
  final String status;
  final String? notes;
  final String? responseNote;
  final String? respondedBy;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final AthleteSummary athlete;

  factory CallupSummary.fromMap(Map<String, dynamic> map) {
    final rawAthlete = map['athlete_profiles'];
    final athleteMap = rawAthlete is Map
        ? Map<String, dynamic>.from(rawAthlete)
        : <String, dynamic>{};

    return CallupSummary(
      id: (map['id'] ?? '').toString(),
      eventId: (map['event_id'] ?? '').toString(),
      athleteProfileId: (map['athlete_profile_id'] ?? '').toString(),
      status: (map['status'] ?? 'called').toString(),
      notes: map['notes']?.toString(),
      responseNote: map['response_note']?.toString(),
      respondedBy: map['responded_by']?.toString(),
      respondedAt: DateTime.tryParse((map['responded_at'] ?? '').toString()),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
      athlete: AthleteSummary.fromMap(athleteMap),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'called':
        return 'In attesa';
      case 'confirmed':
        return 'Confermato';
      case 'declined':
        return 'Non disponibile';
      case 'removed':
        return 'Rimosso';
      default:
        return status;
    }
  }

  bool get isWaiting => status == 'called';

  bool get isConfirmed => status == 'confirmed';

  bool get isDeclined => status == 'declined';
}
