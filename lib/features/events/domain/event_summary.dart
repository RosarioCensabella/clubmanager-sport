class EventSummary {
  const EventSummary({
    required this.id,
    required this.clubId,
    required this.type,
    required this.title,
    required this.startsAt,
    required this.requireRsvp,
    required this.visibility,
    required this.status,
    this.teamId,
    this.teamName,
    this.description,
    this.endsAt,
    this.locationName,
    this.address,
  });

  final String id;
  final String clubId;
  final String? teamId;
  final String? teamName;
  final String type;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? locationName;
  final String? address;
  final bool requireRsvp;
  final String visibility;
  final String status;

  factory EventSummary.fromMap(Map<String, dynamic> map) {
    final rawTeam = map['teams'];
    final teamMap = rawTeam is Map
        ? Map<String, dynamic>.from(rawTeam)
        : <String, dynamic>{};

    return EventSummary(
      id: (map['id'] ?? '').toString(),
      clubId: (map['club_id'] ?? '').toString(),
      teamId: map['team_id']?.toString(),
      teamName: teamMap['name']?.toString(),
      type: (map['type'] ?? 'other').toString(),
      title: (map['title'] ?? '').toString(),
      description: map['description']?.toString(),
      startsAt:
          DateTime.tryParse((map['starts_at'] ?? '').toString()) ??
          DateTime.now(),
      endsAt: DateTime.tryParse((map['ends_at'] ?? '').toString()),
      locationName: map['location_name']?.toString(),
      address: map['address']?.toString(),
      requireRsvp: map['require_rsvp'] == true,
      visibility: (map['visibility'] ?? 'team').toString(),
      status: (map['status'] ?? 'scheduled').toString(),
    );
  }

  String get typeLabel {
    switch (type) {
      case 'training':
        return 'Allenamento';
      case 'match':
        return 'Partita';
      case 'tournament':
        return 'Torneo';
      case 'meeting':
        return 'Riunione';
      case 'medical_visit':
        return 'Visita medica';
      case 'social_event':
        return 'Evento sociale';
      case 'payment_deadline':
        return 'Scadenza pagamento';
      default:
        return 'Altro';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'scheduled':
        return 'Programmato';
      case 'cancelled':
        return 'Annullato';
      case 'completed':
        return 'Completato';
      default:
        return status;
    }
  }

  String get visibilityLabel {
    switch (visibility) {
      case 'club':
        return 'Club';
      case 'team':
        return 'Squadra';
      case 'private':
        return 'Privato';
      default:
        return visibility;
    }
  }
}
