import '../../../core/permissions/club_role.dart';

enum MemberSummaryType { account, athleteProfile }

class MemberSummary {
  const MemberSummary({
    required this.type,
    required this.membershipId,
    required this.clubId,
    required this.userId,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.teamAssignments,
    required this.parentRelations,
    required this.athleteProfiles,
    this.firstName,
    this.lastName,
    this.athleteProfileId,
  });

  final MemberSummaryType type;
  final String membershipId;
  final String clubId;
  final String userId;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? athleteProfileId;
  final ClubRole role;
  final String status;
  final DateTime createdAt;
  final List<MemberTeamAssignment> teamAssignments;
  final List<MemberParentRelation> parentRelations;
  final List<MemberAthleteProfile> athleteProfiles;

  bool get isAthleteProfileOnly => type == MemberSummaryType.athleteProfile;

  bool get hasUserAccount => userId.trim().isNotEmpty;

  String get fullName {
    final value = [
      firstName?.trim(),
      lastName?.trim(),
    ].where((part) => part != null && part.isNotEmpty).join(' ');

    if (value.trim().isNotEmpty) {
      return value;
    }

    if (athleteProfiles.isNotEmpty) {
      return athleteProfiles.first.athleteName;
    }

    if (email.trim().isNotEmpty) {
      return email;
    }

    if (isAthleteProfileOnly) {
      return 'Scheda atleta senza account';
    }

    return 'Account senza profilo';
  }

  String get initials {
    final name = fullName.trim();

    if (name.isEmpty) {
      return '?';
    }

    final parts = name.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String get roleLabel => role.label;

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Attivo';
      case 'pending':
        return 'In attesa';
      case 'suspended':
        return 'Sospeso';
      case 'removed':
        return 'Rimosso';
      default:
        return status;
    }
  }

  String get searchableText {
    return [
      fullName,
      email,
      role.label,
      statusLabel,
      for (final assignment in teamAssignments) assignment.teamName,
      for (final relation in parentRelations) relation.athleteName,
      for (final athlete in athleteProfiles) athlete.athleteName,
      for (final athlete in athleteProfiles) athlete.teamName ?? '',
    ].join(' ').toLowerCase();
  }

  factory MemberSummary.fromMaps({
    required Map<String, dynamic> membershipMap,
    required Map<String, dynamic>? profileMap,
    required List<Map<String, dynamic>> teamAssignmentMaps,
    required List<Map<String, dynamic>> parentRelationMaps,
    required List<Map<String, dynamic>> athleteProfileMaps,
  }) {
    return MemberSummary(
      type: MemberSummaryType.account,
      membershipId: (membershipMap['id'] ?? '').toString(),
      clubId: (membershipMap['club_id'] ?? '').toString(),
      userId: (membershipMap['user_id'] ?? '').toString(),
      email: (profileMap?['email'] ?? '').toString(),
      firstName: profileMap?['first_name']?.toString(),
      lastName: profileMap?['last_name']?.toString(),
      role: clubRoleFromDatabaseValue(membershipMap['role']?.toString()),
      status: (membershipMap['status'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((membershipMap['created_at'] ?? '').toString()) ??
          DateTime.now(),
      teamAssignments: teamAssignmentMaps
          .map(MemberTeamAssignment.fromMap)
          .toList(growable: false),
      parentRelations: parentRelationMaps
          .map(MemberParentRelation.fromMap)
          .toList(growable: false),
      athleteProfiles: athleteProfileMaps
          .map(MemberAthleteProfile.fromMap)
          .toList(growable: false),
    );
  }

  factory MemberSummary.fromAthleteProfileMap({
    required Map<String, dynamic> athleteMap,
    required List<Map<String, dynamic>> teamAssignmentMaps,
  }) {
    final assignments = teamAssignmentMaps
        .map(MemberTeamAssignment.fromMap)
        .toList(growable: true);

    final teamId = athleteMap['team_id']?.toString();
    final teamName = athleteMap['team_name']?.toString();

    if (assignments.isEmpty &&
        teamId != null &&
        teamId.isNotEmpty &&
        teamName != null &&
        teamName.isNotEmpty) {
      assignments.add(
        MemberTeamAssignment(
          id: 'athlete-team:${athleteMap['id']}',
          teamId: teamId,
          teamName: teamName,
          role: ClubRole.athlete,
          status: 'active',
        ),
      );
    }

    return MemberSummary(
      type: MemberSummaryType.athleteProfile,
      membershipId: '',
      clubId: (athleteMap['club_id'] ?? '').toString(),
      userId: (athleteMap['user_id'] ?? '').toString(),
      email: '',
      firstName: athleteMap['first_name']?.toString(),
      lastName: athleteMap['last_name']?.toString(),
      athleteProfileId: (athleteMap['id'] ?? '').toString(),
      role: ClubRole.athlete,
      status: athleteMap['active'] == false ? 'removed' : 'active',
      createdAt:
          DateTime.tryParse((athleteMap['created_at'] ?? '').toString()) ??
          DateTime.now(),
      teamAssignments: assignments.toList(growable: false),
      parentRelations: const [],
      athleteProfiles: [MemberAthleteProfile.fromMap(athleteMap)],
    );
  }
}

class MemberTeamAssignment {
  const MemberTeamAssignment({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.role,
    required this.status,
  });

  final String id;
  final String teamId;
  final String teamName;
  final ClubRole role;
  final String status;

  String get roleLabel => role.label;

  factory MemberTeamAssignment.fromMap(Map<String, dynamic> map) {
    final rawTeam = map['teams'];
    final teamMap = rawTeam is Map
        ? Map<String, dynamic>.from(rawTeam)
        : <String, dynamic>{};

    return MemberTeamAssignment(
      id: (map['id'] ?? '').toString(),
      teamId: (map['team_id'] ?? '').toString(),
      teamName: (map['team_name'] ?? teamMap['name'] ?? 'Squadra').toString(),
      role: clubRoleFromDatabaseValue(map['role']?.toString()),
      status: (map['status'] ?? '').toString(),
    );
  }
}

class MemberParentRelation {
  const MemberParentRelation({
    required this.id,
    required this.athleteId,
    required this.athleteName,
    required this.relationType,
    required this.verified,
  });

  final String id;
  final String athleteId;
  final String athleteName;
  final String relationType;
  final bool verified;

  String get relationLabel {
    switch (relationType) {
      case 'mother':
        return 'Madre';
      case 'father':
        return 'Padre';
      case 'guardian':
        return 'Tutore';
      default:
        return 'Genitore';
    }
  }

  factory MemberParentRelation.fromMap(Map<String, dynamic> map) {
    final rawAthlete = map['athlete_profiles'];
    final athleteMap = rawAthlete is Map
        ? Map<String, dynamic>.from(rawAthlete)
        : <String, dynamic>{};

    final firstName =
        (map['athlete_first_name'] ?? athleteMap['first_name'] ?? '')
            .toString();
    final lastName = (map['athlete_last_name'] ?? athleteMap['last_name'] ?? '')
        .toString();
    final athleteName = '$firstName $lastName'.trim();

    return MemberParentRelation(
      id: (map['id'] ?? '').toString(),
      athleteId: (map['athlete_profile_id'] ?? '').toString(),
      athleteName: athleteName.isEmpty ? 'Atleta' : athleteName,
      relationType: (map['relation_type'] ?? 'parent').toString(),
      verified: map['verified'] == true,
    );
  }
}

class MemberAthleteProfile {
  const MemberAthleteProfile({
    required this.athleteId,
    required this.athleteName,
    this.teamId,
    this.teamName,
  });

  final String athleteId;
  final String athleteName;
  final String? teamId;
  final String? teamName;

  factory MemberAthleteProfile.fromMap(Map<String, dynamic> map) {
    final firstName = (map['first_name'] ?? '').toString();
    final lastName = (map['last_name'] ?? '').toString();
    final athleteName = '$firstName $lastName'.trim();

    return MemberAthleteProfile(
      athleteId: (map['id'] ?? '').toString(),
      athleteName: athleteName.isEmpty ? 'Atleta' : athleteName,
      teamId: map['team_id']?.toString(),
      teamName: map['team_name']?.toString(),
    );
  }
}
