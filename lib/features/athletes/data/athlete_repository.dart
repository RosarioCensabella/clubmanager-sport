import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/athlete_summary.dart';
import '../domain/create_athlete_request.dart';
import '../domain/parent_relation_summary.dart';

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
          .single();

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

      if (request.teamId != null && request.teamId!.trim().isNotEmpty) {
        await _client.from('team_memberships').insert({
          'team_id': request.teamId,
          'athlete_profile_id': athleteId,
          'role': 'athlete',
          'status': 'active',
        });
      }

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
}
