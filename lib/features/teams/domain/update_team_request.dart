class UpdateTeamRequest {
  const UpdateTeamRequest({
    required this.name,
    required this.sport,
    required this.gender,
    this.category,
    this.season,
    this.birthYear,
    this.color,
    this.trainingLocation,
  });

  final String name;
  final String sport;
  final String gender;
  final String? category;
  final String? season;
  final int? birthYear;
  final String? color;
  final String? trainingLocation;

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name.trim(),
      'sport': sport.trim(),
      'category': _nullableTrim(category),
      'season': _nullableTrim(season),
      'birth_year': birthYear,
      'gender': gender,
      'color': _nullableTrim(color),
      'training_location': _nullableTrim(trainingLocation),
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
