import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/callup_summary.dart';

class CallupRepository {
  CallupRepository();

  SupabaseClient get _client => SupabaseService.client;

  Future<AppResult<List<CallupSummary>>> fetchCallupsForEvent({
    required String eventId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (eventId.isEmpty) {
      return const AppFailure('Evento non valido.', code: 'invalid_event_id');
    }

    try {
      final data = await _client
          .from('event_callups')
          .select(
            'id, event_id, athlete_profile_id, status, notes, response_note, responded_by, responded_at, created_at, athlete_profiles(id, club_id, user_id, team_id, first_name, last_name, date_of_birth, jersey_number, sport_role, active, medical_certificate_status, medical_certificate_expiry, staff_notes, teams(id, name))',
          )
          .eq('event_id', eventId)
          .order('created_at');

      final rows = List<Map<String, dynamic>>.from(data);

      final callups = rows
          .map(CallupSummary.fromMap)
          .where((callup) => callup.athlete.id.isNotEmpty)
          .toList(growable: false);

      return AppSuccess(callups);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare le convocazioni.',
        code: 'callups_load_error',
      );
    }
  }

  Future<AppResult<int>> createCallups({
    required String eventId,
    required List<String> athleteProfileIds,
    required String? notes,
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
        'Devi effettuare l’accesso per creare convocazioni.',
        code: 'not_authenticated',
      );
    }

    if (eventId.isEmpty) {
      return const AppFailure('Evento non valido.', code: 'invalid_event_id');
    }

    final uniqueAthleteIds = athleteProfileIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (uniqueAthleteIds.isEmpty) {
      return const AppFailure(
        'Seleziona almeno un atleta.',
        code: 'no_athletes_selected',
      );
    }

    try {
      final rows = uniqueAthleteIds
          .map((athleteId) {
            return {
              'event_id': eventId,
              'athlete_profile_id': athleteId,
              'status': 'called',
              'notes': _nullableTrim(notes),
              'sent_by': user.id,
              'created_by': user.id,
            };
          })
          .toList(growable: false);

      final data = await _client
          .from('event_callups')
          .upsert(rows, onConflict: 'event_id,athlete_profile_id')
          .select('id');

      final createdRows = List<Map<String, dynamic>>.from(data);

      return AppSuccess(createdRows.length);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile creare le convocazioni.',
        code: 'callups_create_error',
      );
    }
  }

  Future<AppResult<void>> updateCallupRsvp({
    required String callupId,
    required String status,
    required String? responseNote,
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
        'Devi effettuare l’accesso per aggiornare la conferma.',
        code: 'not_authenticated',
      );
    }

    if (callupId.isEmpty) {
      return const AppFailure(
        'Convocazione non valida.',
        code: 'invalid_callup_id',
      );
    }

    if (!_allowedRsvpStatuses.contains(status)) {
      return const AppFailure(
        'Stato conferma non valido.',
        code: 'invalid_rsvp_status',
      );
    }

    try {
      await _client
          .from('event_callups')
          .update({
            'status': status,
            'response_note': _nullableTrim(responseNote),
            'responded_by': user.id,
            'responded_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', callupId);

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile aggiornare la conferma presenza.',
        code: 'rsvp_update_error',
      );
    }
  }

  Future<AppResult<void>> removeCallup({required String callupId}) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (callupId.isEmpty) {
      return const AppFailure(
        'Convocazione non valida.',
        code: 'invalid_callup_id',
      );
    }

    try {
      await _client.from('event_callups').delete().eq('id', callupId);

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile rimuovere la convocazione.',
        code: 'callup_remove_error',
      );
    }
  }

  static const Set<String> _allowedRsvpStatuses = {
    'called',
    'confirmed',
    'declined',
  };

  static String? _nullableTrim(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
