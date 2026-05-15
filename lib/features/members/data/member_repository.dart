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

      final teamsById = {
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

      final userIds = {
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

    if (teamRole == ClubRole.unknown) {
      return const AppFailure(
        'Ruolo non valido per assegnazione squadra.',
        code: 'invalid_team_role',
      );
    }

    try {
      await _client.rpc(
        'member_access_assign_user_to_team',
        params: {
          'target_club_id': clubId,
          'target_user_id': userId,
          'target_team_id': teamId,
          'target_role': teamRole.databaseValue,
        },
      );

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
      await _client.rpc(
        'member_access_link_parent_to_athlete',
        params: {
          'target_club_id': clubId,
          'target_parent_user_id': parentUserId,
          'target_athlete_id': athleteId,
          'target_relation_type': relationType,
        },
      );

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
      await _client.rpc(
        'member_access_link_athlete_account',
        params: {
          'target_club_id': clubId,
          'target_athlete_user_id': athleteUserId,
          'target_athlete_id': athleteId,
        },
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
}
