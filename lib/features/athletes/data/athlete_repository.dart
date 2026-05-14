import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/athlete_summary.dart';
import '../domain/create_athlete_request.dart';
import '../domain/parent_relation_summary.dart';
import '../domain/update_athlete_request.dart';

class AthleteRepository {
  AthleteRepository();

  SupabaseClient get _client => SupabaseService.client;

  Future<AppResult<List<AthleteSummary>>> fetchAthletesForClub({
    required String clubId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (clubId.isEmpty) {
      return const AppFailure(
        'Nessun club attivo selezionato.',
        code: 'active_club_missing',
      );
    }

    try {
      final data = await _client
          .from('athlete_profiles')
          .select(
            'id, club_id, user_id, team_id, first_name, last_name, date_of_birth, jersey_number, sport_role, active, medical_certificate_status, medical_certificate_expiry, staff_notes, teams(id, name)',
          )
          .eq('club_id', clubId)
          .isFilter('deleted_at', null)
          .order('last_name')
          .order('first_name');

      final rows = List<Map<String, dynamic>>.from(data);

      final athletes = rows.map(AthleteSummary.fromMap).toList(growable: false);

      return AppSuccess(athletes);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare gli atleti.',
        code: 'athletes_load_error',
      );
    }
  }

  Future<AppResult<AthleteSummary>> fetchAthleteById({
    required String athleteId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (athleteId.isEmpty) {
      return const AppFailure('Atleta non valido.', code: 'invalid_athlete_id');
    }

    try {
      final data = await _client
          .from('athlete_profiles')
          .select(
            'id, club_id, user_id, team_id, first_name, last_name, date_of_birth, jersey_number, sport_role, active, medical_certificate_status, medical_certificate_expiry, staff_notes, teams(id, name)',
          )
          .eq('id', athleteId)
          .maybeSingle();

      if (data == null) {
        return const AppFailure(
          'Atleta non trovato o non disponibile.',
          code: 'athlete_not_found',
        );
      }

      return AppSuccess(
        AthleteSummary.fromMap(Map<String, dynamic>.from(data)),
      );
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare il dettaglio atleta.',
        code: 'athlete_detail_load_error',
      );
    }
  }

  Future<AppResult<String>> createAthlete(CreateAthleteRequest request) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (request.clubId.isEmpty) {
      return const AppFailure(
        'Nessun club attivo selezionato.',
        code: 'active_club_missing',
      );
    }

    try {
      final data = await _client
          .from('athlete_profiles')
          .insert(request.toInsertMap())
          .select('id')
          .single();

      final athleteId = (data['id'] ?? '').toString();

      if (athleteId.isEmpty) {
        return const AppFailure(
          'Atleta creato, ma identificativo non ricevuto.',
          code: 'athlete_created_without_id',
        );
      }

      await _syncTeamMembership(
        athleteId: athleteId,
        oldTeamId: null,
        newTeamId: request.teamId,
        userId: null,
      );

      return AppSuccess(athleteId);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile creare l’atleta. Riprova tra poco.',
        code: 'athlete_create_error',
      );
    }
  }

  Future<AppResult<void>> updateAthlete({
    required String athleteId,
    required UpdateAthleteRequest request,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (athleteId.trim().isEmpty) {
      return const AppFailure('Atleta non valido.', code: 'invalid_athlete_id');
    }

    final athleteResult = await fetchAthleteById(athleteId: athleteId);

    switch (athleteResult) {
      case AppFailure(:final message, :final code):
        return AppFailure(message, code: code);

      case AppSuccess(:final data):
        try {
          await _client
              .from('athlete_profiles')
              .update(request.toUpdateMap())
              .eq('id', athleteId);

          await _syncTeamMembership(
            athleteId: athleteId,
            oldTeamId: data.teamId,
            newTeamId: request.teamId,
            userId: data.userId,
          );

          return const AppSuccess(null);
        } on PostgrestException catch (error) {
          return AppFailure(error.message, code: error.code);
        } catch (_) {
          return const AppFailure(
            'Impossibile aggiornare l’atleta.',
            code: 'athlete_update_error',
          );
        }
    }
  }

  Future<AppResult<void>> archiveAthlete({
    required String athleteId,
    String? reason,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    final user = _client.auth.currentUser;

    if (user == null) {
      return const AppFailure(
        'Devi effettuare l’accesso per archiviare l’atleta.',
        code: 'not_authenticated',
      );
    }

    if (athleteId.trim().isEmpty) {
      return const AppFailure('Atleta non valido.', code: 'invalid_athlete_id');
    }

    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await _client
          .from('athlete_profiles')
          .update({
            'active': false,
            'deleted_at': now,
            'archived_at': now,
            'archived_by': user.id,
            'archive_reason': _nullableTrim(reason),
          })
          .eq('id', athleteId);

      await _client
          .from('team_memberships')
          .update({'status': 'removed'})
          .eq('athlete_profile_id', athleteId)
          .eq('role', 'athlete');

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile archiviare l’atleta.',
        code: 'athlete_archive_error',
      );
    }
  }

  Future<AppResult<String>> linkAthleteAccountByEmail({
    required String athleteId,
    required String email,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (athleteId.trim().isEmpty) {
      return const AppFailure('Atleta non valido.', code: 'invalid_athlete_id');
    }

    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      return const AppFailure(
        'Email account atleta mancante.',
        code: 'missing_athlete_email',
      );
    }

    final athleteResult = await fetchAthleteById(athleteId: athleteId);

    switch (athleteResult) {
      case AppFailure(:final message, :final code):
        return AppFailure(message, code: code);

      case AppSuccess(:final data):
        try {
          final profilesData = await _client
              .from('profiles')
              .select('id, email, first_name, last_name')
              .eq('email', normalizedEmail)
              .limit(1);

          final profiles = List<Map<String, dynamic>>.from(profilesData);

          if (profiles.isEmpty) {
            return const AppFailure(
              'Account non trovato. Invita prima l’atleta e riprova dopo la registrazione tramite invito.',
              code: 'athlete_profile_not_found',
            );
          }

          final userId = (profiles.first['id'] ?? '').toString();

          if (userId.isEmpty) {
            return const AppFailure(
              'Profilo account atleta non valido.',
              code: 'invalid_athlete_profile',
            );
          }

          await _client
              .from('athlete_profiles')
              .update({'user_id': userId, 'active': true})
              .eq('id', athleteId);

          await _ensureClubMembership(clubId: data.clubId, userId: userId);

          await _syncTeamMembership(
            athleteId: athleteId,
            oldTeamId: data.teamId,
            newTeamId: data.teamId,
            userId: userId,
          );

          return AppSuccess(userId);
        } on PostgrestException catch (error) {
          return AppFailure(error.message, code: error.code);
        } catch (_) {
          return const AppFailure(
            'Impossibile collegare l’account atleta.',
            code: 'athlete_account_link_error',
          );
        }
    }
  }

  Future<void> _ensureClubMembership({
    required String clubId,
    required String userId,
  }) async {
    final membershipsData = await _client
        .from('club_memberships')
        .select('id, role, status')
        .eq('club_id', clubId)
        .eq('user_id', userId)
        .limit(1);

    final memberships = List<Map<String, dynamic>>.from(membershipsData);

    if (memberships.isNotEmpty) {
      final membershipId = (memberships.first['id'] ?? '').toString();

      if (membershipId.isNotEmpty) {
        await _client
            .from('club_memberships')
            .update({'status': 'active'})
            .eq('id', membershipId);
      }

      return;
    }

    await _client.from('club_memberships').insert({
      'club_id': clubId,
      'user_id': userId,
      'role': 'athlete',
      'status': 'active',
    });
  }

  Future<void> _syncTeamMembership({
    required String athleteId,
    required String? oldTeamId,
    required String? newTeamId,
    required String? userId,
  }) async {
    final oldTeam = _nullableTrim(oldTeamId);
    final newTeam = _nullableTrim(newTeamId);
    final linkedUserId = _nullableTrim(userId);

    if (oldTeam != null && oldTeam != newTeam) {
      await _client
          .from('team_memberships')
          .delete()
          .eq('team_id', oldTeam)
          .eq('athlete_profile_id', athleteId)
          .eq('role', 'athlete');
    }

    if (newTeam == null) {
      return;
    }

    final byAthleteData = await _client
        .from('team_memberships')
        .select('id')
        .eq('team_id', newTeam)
        .eq('athlete_profile_id', athleteId)
        .eq('role', 'athlete')
        .limit(1);

    final byAthlete = List<Map<String, dynamic>>.from(byAthleteData);

    if (byAthlete.isNotEmpty) {
      final membershipId = (byAthlete.first['id'] ?? '').toString();

      if (membershipId.isNotEmpty) {
        await _client
            .from('team_memberships')
            .update({'user_id': linkedUserId, 'status': 'active'})
            .eq('id', membershipId);
      }

      return;
    }

    if (linkedUserId != null) {
      final byUserData = await _client
          .from('team_memberships')
          .select('id')
          .eq('team_id', newTeam)
          .eq('user_id', linkedUserId)
          .eq('role', 'athlete')
          .limit(1);

      final byUser = List<Map<String, dynamic>>.from(byUserData);

      if (byUser.isNotEmpty) {
        final membershipId = (byUser.first['id'] ?? '').toString();

        if (membershipId.isNotEmpty) {
          await _client
              .from('team_memberships')
              .update({'athlete_profile_id': athleteId, 'status': 'active'})
              .eq('id', membershipId);
        }

        return;
      }
    }

    await _client.from('team_memberships').insert({
      'team_id': newTeam,
      'user_id': linkedUserId,
      'athlete_profile_id': athleteId,
      'role': 'athlete',
      'status': 'active',
    });
  }

  Future<AppResult<List<ParentRelationSummary>>> fetchParentRelations({
    required String athleteId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (athleteId.isEmpty) {
      return const AppFailure('Atleta non valido.', code: 'invalid_athlete_id');
    }

    try {
      final relationData = await _client
          .from('parent_athlete_relations')
          .select(
            'id, parent_user_id, athlete_profile_id, relation_type, verified, created_at',
          )
          .eq('athlete_profile_id', athleteId)
          .order('created_at');

      final relationRows = List<Map<String, dynamic>>.from(relationData);

      if (relationRows.isEmpty) {
        return const AppSuccess([]);
      }

      final parentUserIds = relationRows
          .map((row) => (row['parent_user_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);

      final profilesById = <String, Map<String, dynamic>>{};

      if (parentUserIds.isNotEmpty) {
        final profileData = await _client
            .from('profiles')
            .select('id, email, first_name, last_name')
            .inFilter('id', parentUserIds);

        final profileRows = List<Map<String, dynamic>>.from(profileData);

        for (final profile in profileRows) {
          profilesById[(profile['id'] ?? '').toString()] = profile;
        }
      }

      final relations = relationRows
          .map((relationMap) {
            final parentUserId = (relationMap['parent_user_id'] ?? '')
                .toString();

            return ParentRelationSummary.fromMaps(
              relationMap: relationMap,
              profileMap: profilesById[parentUserId],
            );
          })
          .toList(growable: false);

      return AppSuccess(relations);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare genitori e tutori collegati.',
        code: 'parent_relations_load_error',
      );
    }
  }

  Future<AppResult<String>> linkParentByEmail({
    required String athleteId,
    required String email,
    required String relationType,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (athleteId.isEmpty) {
      return const AppFailure('Atleta non valido.', code: 'invalid_athlete_id');
    }

    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      return const AppFailure(
        'Email genitore/tutore mancante.',
        code: 'missing_parent_email',
      );
    }

    try {
      final profilesData = await _client
          .from('profiles')
          .select('id, email, first_name, last_name')
          .eq('email', normalizedEmail)
          .limit(1);

      final profiles = List<Map<String, dynamic>>.from(profilesData);

      if (profiles.isEmpty) {
        return const AppFailure(
          'Utente non trovato nel club. Invitalo prima come genitore/tutore e riprova dopo la registrazione.',
          code: 'parent_profile_not_found',
        );
      }

      final parentUserId = (profiles.first['id'] ?? '').toString();

      if (parentUserId.isEmpty) {
        return const AppFailure(
          'Profilo genitore/tutore non valido.',
          code: 'invalid_parent_profile',
        );
      }

      final data = await _client
          .from('parent_athlete_relations')
          .insert({
            'parent_user_id': parentUserId,
            'athlete_profile_id': athleteId,
            'relation_type': relationType,
            'verified': true,
          })
          .select('id')
          .single();

      final relationId = (data['id'] ?? '').toString();

      if (relationId.isEmpty) {
        return const AppFailure(
          'Collegamento creato, ma identificativo non ricevuto.',
          code: 'parent_relation_created_without_id',
        );
      }

      return AppSuccess(relationId);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        return const AppFailure(
          'Questo genitore/tutore è già collegato all’atleta.',
          code: 'parent_relation_already_exists',
        );
      }

      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile collegare il genitore/tutore.',
        code: 'parent_relation_create_error',
      );
    }
  }

  Future<AppResult<void>> removeParentRelation({
    required String relationId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (relationId.isEmpty) {
      return const AppFailure(
        'Collegamento non valido.',
        code: 'invalid_relation_id',
      );
    }

    try {
      await _client
          .from('parent_athlete_relations')
          .delete()
          .eq('id', relationId);

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile rimuovere il collegamento.',
        code: 'parent_relation_delete_error',
      );
    }
  }

  static String? _nullableTrim(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
