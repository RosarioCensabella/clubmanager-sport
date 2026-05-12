import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/create_team_request.dart';
import '../domain/team_summary.dart';

class TeamRepository {
  TeamRepository();

  SupabaseClient get _client => SupabaseService.client;

  Future<AppResult<List<TeamSummary>>> fetchTeamsForClub({
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
          .from('teams')
          .select(
            'id, club_id, name, sport, category, season, birth_year, gender, color, training_location',
          )
          .eq('club_id', clubId)
          .isFilter('deleted_at', null)
          .order('name');

      final rows = List<Map<String, dynamic>>.from(data);

      final teams = rows.map(TeamSummary.fromMap).toList(growable: false);

      return AppSuccess(teams);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare le squadre.',
        code: 'teams_load_error',
      );
    }
  }

  Future<AppResult<String>> createTeam(CreateTeamRequest request) async {
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
          .from('teams')
          .insert(request.toInsertMap())
          .select('id')
          .single();

      final teamId = (data['id'] ?? '').toString();

      if (teamId.isEmpty) {
        return const AppFailure(
          'Squadra creata, ma identificativo non ricevuto.',
          code: 'team_created_without_id',
        );
      }

      return AppSuccess(teamId);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile creare la squadra. Riprova tra poco.',
        code: 'team_create_error',
      );
    }
  }
}
