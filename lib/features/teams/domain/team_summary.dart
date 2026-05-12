class TeamSummary {
  const TeamSummary({
    required this.id,
    required this.clubId,
    required this.name,
    required this.sport,
    required this.gender,
    this.category,
    this.season,
    this.birthYear,
    this.color,
    this.trainingLocation,
  });

  final String id;
  final String clubId;
  final String name;
  final String sport;
  final String gender;
  final String? category;
  final String? season;
  final int? birthYear;
  final String? color;
  final String? trainingLocation;

  factory TeamSummary.fromMap(Map<String, dynamic> map) {
    return TeamSummary(
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
