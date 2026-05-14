class TeamDetail {
  const TeamDetail({
    required this.id,
    required this.clubId,
    required this.name,
    required this.sport,
    required this.gender,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.season,
    this.birthYear,
    this.color,
    this.trainingLocation,
    this.headCoachUserId,
    this.assistantCoachUserId,
    this.deletedAt,
    this.archivedAt,
    this.archivedBy,
    this.archiveReason,
  });

  final String id;
  final String clubId;
  final String name;
  final String sport;
  final String gender;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? category;
  final String? season;
  final int? birthYear;
  final String? color;
  final String? trainingLocation;
  final String? headCoachUserId;
  final String? assistantCoachUserId;
  final DateTime? deletedAt;
  final DateTime? archivedAt;
  final String? archivedBy;
  final String? archiveReason;

  bool get isArchived => deletedAt != null || archivedAt != null;

  factory TeamDetail.fromMap(Map<String, dynamic> map) {
    return TeamDetail(
      id: (map['id'] ?? '').toString(),
      clubId: (map['club_id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      sport: (map['sport'] ?? '').toString(),
      category: map['category']?.toString(),
      season: map['season']?.toString(),
      birthYear: map['birth_year'] is int ? map['birth_year'] as int : null,
      gender: (map['gender'] ?? 'unspecified').toString(),
      color: map['color']?.toString(),
      trainingLocation: map['training_location']?.toString(),
      headCoachUserId: map['head_coach_user_id']?.toString(),
      assistantCoachUserId: map['assistant_coach_user_id']?.toString(),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse((map['updated_at'] ?? '').toString()) ??
          DateTime.now(),
      deletedAt: DateTime.tryParse((map['deleted_at'] ?? '').toString()),
      archivedAt: DateTime.tryParse((map['archived_at'] ?? '').toString()),
      archivedBy: map['archived_by']?.toString(),
      archiveReason: map['archive_reason']?.toString(),
    );
  }

  String get genderLabel {
    switch (gender) {
      case 'male':
        return 'Maschile';
      case 'female':
        return 'Femminile';
      case 'mixed':
        return 'Mista';
      default:
        return 'Non specificato';
    }
  }
}
