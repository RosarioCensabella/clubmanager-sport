import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/create_team_request.dart';
import '../domain/team_detail.dart';
import '../domain/team_summary.dart';
import '../domain/update_team_request.dart';

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

  Future<AppResult<TeamDetail>> fetchTeamById({
    required String teamId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (teamId.trim().isEmpty) {
      return const AppFailure(
        'Squadra non valida.',
        code: 'invalid_team_id',
      );
    }

    try {
      final data = await _client
          .from('teams')
          .select(
            'id, club_id, name, sport, category, season, birth_year, gender, color, training_location, head_coach_user_id, assistant_coach_user_id, created_at, updated_at, deleted_at, archived_at, archived_by, archive_reason',
          )
          .eq('id', teamId)
          .maybeSingle();

      if (data == null) {
        return const AppFailure(
          'Squadra non trovata o non disponibile.',
          code: 'team_not_found',
        );
      }

      return AppSuccess(TeamDetail.fromMap(Map<String, dynamic>.from(data)));
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare il dettaglio squadra.',
        code: 'team_detail_load_error',
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

  Future<AppResult<void>> updateTeam({
    required String teamId,
    required UpdateTeamRequest request,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (teamId.trim().isEmpty) {
      return const AppFailure(
        'Squadra non valida.',
        code: 'invalid_team_id',
      );
    }

    try {
      await _client.from('teams').update(request.toUpdateMap()).eq('id', teamId);

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile aggiornare la squadra.',
        code: 'team_update_error',
      );
    }
  }

  Future<AppResult<void>> archiveTeam({
    required String teamId,
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
        'Devi effettuare l’accesso per archiviare la squadra.',
        code: 'not_authenticated',
      );
    }

    if (teamId.trim().isEmpty) {
      return const AppFailure(
        'Squadra non valida.',
        code: 'invalid_team_id',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await _client.from('teams').update({
        'deleted_at': now,
        'archived_at': now,
        'archived_by': user.id,
        'archive_reason': _nullableTrim(reason),
      }).eq('id', teamId);

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile archiviare la squadra.',
        code: 'team_archive_error',
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