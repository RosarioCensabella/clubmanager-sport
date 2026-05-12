import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/create_event_request.dart';
import '../domain/event_summary.dart';

class EventRepository {
  EventRepository();

  SupabaseClient get _client => SupabaseService.client;

  Future<AppResult<List<EventSummary>>> fetchEventsForClub({
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
          .from('events')
          .select(
            'id, club_id, team_id, type, title, description, starts_at, ends_at, location_name, address, require_rsvp, visibility, status, teams(id, name)',
          )
          .eq('club_id', clubId)
          .isFilter('deleted_at', null)
          .order('starts_at');

      final rows = List<Map<String, dynamic>>.from(data);

      final events = rows.map(EventSummary.fromMap).toList(growable: false);

      return AppSuccess(events);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare gli eventi.',
        code: 'events_load_error',
      );
    }
  }

  Future<AppResult<EventSummary>> fetchEventById({
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
          .from('events')
          .select(
            'id, club_id, team_id, type, title, description, starts_at, ends_at, location_name, address, require_rsvp, visibility, status, teams(id, name)',
          )
          .eq('id', eventId)
          .single();

      return AppSuccess(EventSummary.fromMap(Map<String, dynamic>.from(data)));
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare il dettaglio evento.',
        code: 'event_detail_load_error',
      );
    }
  }

  Future<AppResult<String>> createEvent({
    required CreateEventRequest request,
  }) async {
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
          .from('events')
          .insert(request.toInsertMap())
          .select('id')
          .single();

      final eventId = (data['id'] ?? '').toString();

      if (eventId.isEmpty) {
        return const AppFailure(
          'Evento creato, ma identificativo non ricevuto.',
          code: 'event_created_without_id',
        );
      }

      return AppSuccess(eventId);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile creare l’evento. Riprova tra poco.',
        code: 'event_create_error',
      );
    }
  }

  String? currentUserId() {
    if (!SupabaseService.isConfigured) {
      return null;
    }

    return _client.auth.currentUser?.id;
  }
}
