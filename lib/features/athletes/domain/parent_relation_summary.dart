class ParentRelationSummary {
  const ParentRelationSummary({
    required this.id,
    required this.parentUserId,
    required this.athleteProfileId,
    required this.relationType,
    required this.verified,
    required this.createdAt,
    required this.parentEmail,
    this.parentFirstName,
    this.parentLastName,
  });

  final String id;
  final String parentUserId;
  final String athleteProfileId;
  final String relationType;
  final bool verified;
  final DateTime createdAt;
  final String parentEmail;
  final String? parentFirstName;
  final String? parentLastName;

  String get parentFullName {
    final fullName = '${parentFirstName ?? ''} ${parentLastName ?? ''}'.trim();

    if (fullName.isEmpty) {
      return parentEmail;
    }

    return fullName;
  }

  String get relationLabel {
    switch (relationType) {
      case 'mother':
        return 'Madre';
      case 'father':
        return 'Padre';
      case 'guardian':
        return 'Tutore';
      case 'parent':
        return 'Genitore';
      default:
        return relationType;
    }
  }

  factory ParentRelationSummary.fromMaps({
    required Map<String, dynamic> relationMap,
    required Map<String, dynamic>? profileMap,
  }) {
    return ParentRelationSummary(
      id: (relationMap['id'] ?? '').toString(),
      parentUserId: (relationMap['parent_user_id'] ?? '').toString(),
      athleteProfileId: (relationMap['athlete_profile_id'] ?? '').toString(),
      relationType: (relationMap['relation_type'] ?? 'parent').toString(),
      verified: relationMap['verified'] == true,
      createdAt:
          DateTime.tryParse((relationMap['created_at'] ?? '').toString()) ??
          DateTime.now(),
      parentEmail: (profileMap?['email'] ?? '').toString(),
      parentFirstName: profileMap?['first_name']?.toString(),
      parentLastName: profileMap?['last_name']?.toString(),
    );
  }
}
