class CreateEventRequest {
  const CreateEventRequest({
    required this.clubId,
    required this.type,
    required this.title,
    required this.startsAt,
    required this.createdBy,
    required this.requireRsvp,
    required this.visibility,
    this.teamId,
    this.description,
    this.endsAt,
    this.locationName,
    this.address,
  });

  final String clubId;
  final String? teamId;
  final String type;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? locationName;
  final String? address;
  final String createdBy;
  final bool requireRsvp;
  final String visibility;

  Map<String, dynamic> toInsertMap() {
    return {
      'club_id': clubId,
      'team_id': _nullableTrim(teamId),
      'type': type,
      'title': title.trim(),
      'description': _nullableTrim(description),
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt?.toUtc().toIso8601String(),
      'location_name': _nullableTrim(locationName),
      'address': _nullableTrim(address),
      'created_by': createdBy,
      'require_rsvp': requireRsvp,
      'visibility': visibility,
      'status': 'scheduled',
      'notify_members': true,
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
