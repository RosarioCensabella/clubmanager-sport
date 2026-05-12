import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/athlete_summary.dart';
import '../domain/create_athlete_request.dart';

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
}
