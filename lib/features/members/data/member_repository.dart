import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/permissions/club_role.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/member_summary.dart';

class MemberRepository {
  MemberRepository();

  SupabaseClient get _client => SupabaseService.client;

  Future<AppResult<List<MemberSummary>>> fetchMembersForClub({
    required String clubId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (clubId.trim().isEmpty) {
      return const AppFailure(
        'Nessun club attivo selezionato.',
        code: 'active_club_missing',
      );
    }

    try {
      final teamsData = await _client
          .from('teams')
          .select('id, name')
          .eq('club_id', clubId)
          .isFilter('deleted_at', null)
          .order('name');

      final teamRows = List<Map<String, dynamic>>.from(teamsData);
      final teamIds = teamRows
          .map((row) => (row['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);

      final teamsById = <String, String>{
        for (final row in teamRows)
          (row['id'] ?? '').toString(): (row['name'] ?? 'Squadra').toString(),
      };

      final membershipData = await _client
          .from('club_memberships')
          .select('id, club_id, user_id, role, status, created_at')
          .eq('club_id', clubId)
          .order('created_at');

      final membershipRows = List<Map<String, dynamic>>.from(membershipData);

      final athleteData = await _client
          .from('athlete_profiles')
          .select(
            'id, club_id, user_id, team_id, first_name, last_name, active, created_at',
          )
          .eq('club_id', clubId)
          .isFilter('deleted_at', null)
          .order('last_name')
          .order('first_name');

      final athleteRows = List<Map<String, dynamic>>.from(athleteData)
          .map((row) {
            final teamId = row['team_id']?.toString();

            return Map<String, dynamic>.from(row)
              ..['team_name'] = teamId == null ? null : teamsById[teamId];
          })
          .toList(growable: false);

      final athleteIds = athleteRows
          .map((row) => (row['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);

      final userIds = <String>{
        for (final row in membershipRows)
          if ((row['user_id'] ?? '').toString().isNotEmpty)
            (row['user_id'] ?? '').toString(),
        for (final row in athleteRows)
          if ((row['user_id'] ?? '').toString().isNotEmpty)
            (row['user_id'] ?? '').toString(),
      }.toList(growable: false);

      final profilesById = <String, Map<String, dynamic>>{};
      final teamAssignmentsByUserId = <String, List<Map<String, dynamic>>>{};
      final teamAssignmentsByAthleteId = <String, List<Map<String, dynamic>>>{};
      final parentRelationsByUserId = <String, List<Map<String, dynamic>>>{};
      final athleteProfilesByUserId = <String, List<Map<String, dynamic>>>{};

      for (final athlete in athleteRows) {
        final userId = athlete['user_id']?.toString();

        if (userId == null || userId.isEmpty) {
          continue;
        }

        athleteProfilesByUserId
            .putIfAbsent(userId, () => <Map<String, dynamic>>[])
            .add(athlete);
      }

      if (userIds.isNotEmpty) {
        final profileData = await _client
            .from('profiles')
            .select('id, email, first_name, last_name')
            .inFilter('id', userIds);

        final profileRows = List<Map<String, dynamic>>.from(profileData);

        for (final profile in profileRows) {
          profilesById[(profile['id'] ?? '').toString()] = profile;
        }
      }

      if (teamIds.isNotEmpty) {
        final teamAssignmentData = await _client
            .from('team_memberships')
            .select('id, team_id, user_id, athlete_profile_id, role, status')
            .inFilter('team_id', teamIds)
            .eq('status', 'active');

        final teamAssignmentRows = List<Map<String, dynamic>>.from(
          teamAssignmentData,
        );

        for (final assignment in teamAssignmentRows) {
          final teamId = (assignment['team_id'] ?? '').toString();
          final enrichedAssignment = Map<String, dynamic>.from(assignment)
            ..['team_name'] = teamsById[teamId] ?? 'Squadra';

          final userId = (assignment['user_id'] ?? '').toString();

          if (userId.isNotEmpty) {
            teamAssignmentsByUserId
                .putIfAbsent(userId, () => <Map<String, dynamic>>[])
                .add(enrichedAssignment);
          }

          final athleteId = (assignment['athlete_profile_id'] ?? '').toString();

          if (athleteId.isNotEmpty) {
            teamAssignmentsByAthleteId
                .putIfAbsent(athleteId, () => <Map<String, dynamic>>[])
                .add(enrichedAssignment);
          }
        }
      }

      if (athleteIds.isNotEmpty) {
        final parentRelationData = await _client
            .from('parent_athlete_relations')
            .select(
              'id, parent_user_id, athlete_profile_id, relation_type, verified',
            )
            .inFilter('athlete_profile_id', athleteIds)
            .eq('verified', true);

        final parentRelationRows = List<Map<String, dynamic>>.from(
          parentRelationData,
        );

        final athletesById = <String, Map<String, dynamic>>{
          for (final athlete in athleteRows)
            (athlete['id'] ?? '').toString(): athlete,
        };

        for (final relation in parentRelationRows) {
          final parentUserId = (relation['parent_user_id'] ?? '').toString();

          if (parentUserId.isEmpty) {
            continue;
          }

          final athleteId = (relation['athlete_profile_id'] ?? '').toString();
          final athlete = athletesById[athleteId];

          final enrichedRelation = Map<String, dynamic>.from(relation)
            ..['athlete_first_name'] = athlete?['first_name']
            ..['athlete_last_name'] = athlete?['last_name'];

          parentRelationsByUserId
              .putIfAbsent(parentUserId, () => <Map<String, dynamic>>[])
              .add(enrichedRelation);
        }
      }

      final members = <MemberSummary>[];

      final membershipUserIds = <String>{};

      for (final membershipMap in membershipRows) {
        final userId = (membershipMap['user_id'] ?? '').toString();

        if (userId.isNotEmpty) {
          membershipUserIds.add(userId);
        }

        members.add(
          MemberSummary.fromMaps(
            membershipMap: membershipMap,
            profileMap: profilesById[userId],
            teamAssignmentMaps: teamAssignmentsByUserId[userId] ?? const [],
            parentRelationMaps: parentRelationsByUserId[userId] ?? const [],
            athleteProfileMaps: athleteProfilesByUserId[userId] ?? const [],
          ),
        );
      }

      for (final athleteMap in athleteRows) {
        final userId = athleteMap['user_id']?.toString();

        if (userId != null &&
            userId.isNotEmpty &&
            membershipUserIds.contains(userId)) {
          continue;
        }

        members.add(
          MemberSummary.fromAthleteProfileMap(
            athleteMap: athleteMap,
            teamAssignmentMaps:
                teamAssignmentsByAthleteId[(athleteMap['id'] ?? '')
                    .toString()] ??
                const [],
          ),
        );
      }

      members.sort((a, b) => a.fullName.compareTo(b.fullName));

      return AppSuccess(members);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare persone e accessi del club.',
        code: 'members_load_error',
      );
    }
  }

  Future<AppResult<void>> assignUserToTeam({
    required String clubId,
    required String userId,
    required String teamId,
    required ClubRole teamRole,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (clubId.trim().isEmpty ||
        userId.trim().isEmpty ||
        teamId.trim().isEmpty) {
      return const AppFailure(
        'Dati assegnazione incompleti.',
        code: 'invalid_team_assignment',
      );
    }

    if (!_isAssignableTeamRole(teamRole)) {
      return const AppFailure(
        'Ruolo non valido per assegnazione squadra.',
        code: 'invalid_team_role',
      );
    }

    try {
      await _ensureClubMembership(
        clubId: clubId,
        userId: userId,
        role: teamRole,
      );

      final existingData = await _client
          .from('team_memberships')
          .select('id')
          .eq('team_id', teamId)
          .eq('user_id', userId)
          .eq('role', teamRole.databaseValue)
          .limit(1);

      final existingRows = List<Map<String, dynamic>>.from(existingData);

      if (existingRows.isNotEmpty) {
        final assignmentId = (existingRows.first['id'] ?? '').toString();

        if (assignmentId.isNotEmpty) {
          await _client
              .from('team_memberships')
              .update({'status': 'active'})
              .eq('id', assignmentId);
        }

        return const AppSuccess(null);
      }

      await _client.from('team_memberships').insert({
        'team_id': teamId,
        'user_id': userId,
        'role': teamRole.databaseValue,
        'status': 'active',
      });

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile assegnare la persona alla squadra.',
        code: 'team_assignment_error',
      );
    }
  }

  Future<AppResult<void>> linkParentToAthlete({
    required String clubId,
    required String parentUserId,
    required String athleteId,
    required String relationType,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (clubId.trim().isEmpty ||
        parentUserId.trim().isEmpty ||
        athleteId.trim().isEmpty) {
      return const AppFailure(
        'Dati collegamento incompleti.',
        code: 'invalid_parent_relation',
      );
    }

    try {
      final athleteData = await _client
          .from('athlete_profiles')
          .select('id, club_id')
          .eq('id', athleteId)
          .eq('club_id', clubId)
          .maybeSingle();

      if (athleteData == null) {
        return const AppFailure(
          'Atleta non trovato nel club attivo.',
          code: 'athlete_not_found',
        );
      }

      await _ensureClubMembership(
        clubId: clubId,
        userId: parentUserId,
        role: ClubRole.parent,
      );

      final existingData = await _client
          .from('parent_athlete_relations')
          .select('id')
          .eq('parent_user_id', parentUserId)
          .eq('athlete_profile_id', athleteId)
          .limit(1);

      final existingRows = List<Map<String, dynamic>>.from(existingData);

      if (existingRows.isNotEmpty) {
        final relationId = (existingRows.first['id'] ?? '').toString();

        if (relationId.isNotEmpty) {
          await _client
              .from('parent_athlete_relations')
              .update({'relation_type': relationType, 'verified': true})
              .eq('id', relationId);
        }

        return const AppSuccess(null);
      }

      await _client.from('parent_athlete_relations').insert({
        'parent_user_id': parentUserId,
        'athlete_profile_id': athleteId,
        'relation_type': relationType,
        'verified': true,
      });

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile collegare genitore/tutore e atleta.',
        code: 'parent_athlete_link_error',
      );
    }
  }

  Future<AppResult<void>> linkAthleteAccount({
    required String clubId,
    required String athleteUserId,
    required String athleteId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (clubId.trim().isEmpty ||
        athleteUserId.trim().isEmpty ||
        athleteId.trim().isEmpty) {
      return const AppFailure(
        'Dati collegamento atleta incompleti.',
        code: 'invalid_athlete_account_link',
      );
    }

    try {
      final athleteData = await _client
          .from('athlete_profiles')
          .select('id, club_id, team_id, user_id')
          .eq('id', athleteId)
          .eq('club_id', clubId)
          .maybeSingle();

      if (athleteData == null) {
        return const AppFailure(
          'Scheda atleta non trovata nel club attivo.',
          code: 'athlete_not_found',
        );
      }

      final existingUserId = athleteData['user_id']?.toString();

      if (existingUserId != null &&
          existingUserId.isNotEmpty &&
          existingUserId != athleteUserId) {
        return const AppFailure(
          'Questa scheda atleta è già collegata a un altro account.',
          code: 'athlete_already_linked',
        );
      }

      await _ensureClubMembership(
        clubId: clubId,
        userId: athleteUserId,
        role: ClubRole.athlete,
      );

      await _client
          .from('athlete_profiles')
          .update({'user_id': athleteUserId, 'active': true})
          .eq('id', athleteId);

      final teamId = athleteData['team_id']?.toString();

      await _syncAthleteTeamMembership(
        athleteId: athleteId,
        athleteUserId: athleteUserId,
        teamId: teamId,
      );

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile collegare account e scheda atleta.',
        code: 'athlete_account_link_error',
      );
    }
  }

  Future<void> _ensureClubMembership({
    required String clubId,
    required String userId,
    required ClubRole role,
  }) async {
    final membershipData = await _client
        .from('club_memberships')
        .select('id, role, status')
        .eq('club_id', clubId)
        .eq('user_id', userId)
        .limit(1);

    final memberships = List<Map<String, dynamic>>.from(membershipData);

    if (memberships.isEmpty) {
      await _client.from('club_memberships').insert({
        'club_id': clubId,
        'user_id': userId,
        'role': role.databaseValue,
        'status': 'active',
      });

      return;
    }

    final membership = memberships.first;
    final membershipId = (membership['id'] ?? '').toString();
    final currentRole = clubRoleFromDatabaseValue(
      membership['role']?.toString(),
    );

    if (membershipId.isEmpty) {
      return;
    }

    await _client
        .from('club_memberships')
        .update({
          'role': _preserveHigherRole(currentRole, role).databaseValue,
          'status': 'active',
        })
        .eq('id', membershipId);
  }

  ClubRole _preserveHigherRole(ClubRole currentRole, ClubRole requestedRole) {
    if (currentRole == ClubRole.owner || currentRole == ClubRole.admin) {
      return currentRole;
    }

    if (currentRole == ClubRole.teamManager ||
        currentRole == ClubRole.coach ||
        currentRole == ClubRole.staff) {
      return currentRole;
    }

    return requestedRole;
  }

  Future<void> _syncAthleteTeamMembership({
    required String athleteId,
    required String athleteUserId,
    required String? teamId,
  }) async {
    final normalizedTeamId = teamId?.trim();

    if (normalizedTeamId == null || normalizedTeamId.isEmpty) {
      return;
    }

    final byAthleteData = await _client
        .from('team_memberships')
        .select('id')
        .eq('team_id', normalizedTeamId)
        .eq('athlete_profile_id', athleteId)
        .eq('role', 'athlete')
        .limit(1);

    final byAthleteRows = List<Map<String, dynamic>>.from(byAthleteData);

    if (byAthleteRows.isNotEmpty) {
      final assignmentId = (byAthleteRows.first['id'] ?? '').toString();

      if (assignmentId.isNotEmpty) {
        await _client
            .from('team_memberships')
            .update({'user_id': athleteUserId, 'status': 'active'})
            .eq('id', assignmentId);
      }

      return;
    }

    final byUserData = await _client
        .from('team_memberships')
        .select('id')
        .eq('team_id', normalizedTeamId)
        .eq('user_id', athleteUserId)
        .eq('role', 'athlete')
        .limit(1);

    final byUserRows = List<Map<String, dynamic>>.from(byUserData);

    if (byUserRows.isNotEmpty) {
      final assignmentId = (byUserRows.first['id'] ?? '').toString();

      if (assignmentId.isNotEmpty) {
        await _client
            .from('team_memberships')
            .update({'athlete_profile_id': athleteId, 'status': 'active'})
            .eq('id', assignmentId);
      }

      return;
    }

    await _client.from('team_memberships').insert({
      'team_id': normalizedTeamId,
      'user_id': athleteUserId,
      'athlete_profile_id': athleteId,
      'role': 'athlete',
      'status': 'active',
    });
  }

  bool _isAssignableTeamRole(ClubRole role) {
    return role == ClubRole.teamManager ||
        role == ClubRole.coach ||
        role == ClubRole.staff;
  }
}
