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
  });

  final String id;
  final String eventId;
  final String athleteProfileId;
  final String status;
  final String? notes;
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
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
      athlete: AthleteSummary.fromMap(athleteMap),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'called':
        return 'Convocato';
      case 'removed':
        return 'Rimosso';
      case 'confirmed':
        return 'Confermato';
      case 'declined':
        return 'Non disponibile';
      default:
        return status;
    }
  }
}
