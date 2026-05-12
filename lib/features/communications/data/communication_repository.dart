import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/communication_summary.dart';
import '../domain/create_communication_request.dart';

class CommunicationRepository {
  CommunicationRepository();

  SupabaseClient get _client => SupabaseService.client;

  String? currentUserId() {
    if (!SupabaseService.isConfigured) {
      return null;
    }

    return _client.auth.currentUser?.id;
  }

  Future<AppResult<List<CommunicationSummary>>> fetchCommunicationsForClub({
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
      final userId = _client.auth.currentUser?.id;

      final data = await _client
          .from('announcements')
          .select(
            'id, club_id, team_id, title, body, content, priority, visibility, status, allow_comments, send_push, pinned, created_by, published_at, publish_at, expires_at, created_at, teams(id, name)',
          )
          .eq('club_id', clubId)
          .isFilter('deleted_at', null)
          .order('pinned', ascending: false)
          .order('created_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(data);

      final readIds = <String>{};

      if (userId != null && userId.isNotEmpty && rows.isNotEmpty) {
        final communicationIds = rows
            .map((row) => (row['id'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toList(growable: false);

        final readsData = await _client
            .from('announcement_reads')
            .select('announcement_id')
            .eq('user_id', userId)
            .inFilter('announcement_id', communicationIds);

        final readRows = List<Map<String, dynamic>>.from(readsData);

        for (final row in readRows) {
          readIds.add((row['announcement_id'] ?? '').toString());
        }
      }

      final communications = rows
          .map(
            (row) => CommunicationSummary.fromMap(
              row,
              isRead: readIds.contains((row['id'] ?? '').toString()),
            ),
          )
          .toList(growable: false);

      return AppSuccess(communications);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare le comunicazioni.',
        code: 'communications_load_error',
      );
    }
  }

  Future<AppResult<CommunicationSummary>> fetchCommunicationById({
    required String communicationId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (communicationId.isEmpty) {
      return const AppFailure(
        'Comunicazione non valida.',
        code: 'invalid_communication_id',
      );
    }

    try {
      final data = await _client
          .from('announcements')
          .select(
            'id, club_id, team_id, title, body, content, priority, visibility, status, allow_comments, send_push, pinned, created_by, published_at, publish_at, expires_at, created_at, teams(id, name)',
          )
          .eq('id', communicationId)
          .single();

      final userId = _client.auth.currentUser?.id;
      var isRead = false;

      if (userId != null && userId.isNotEmpty) {
        final readsData = await _client
            .from('announcement_reads')
            .select('announcement_id')
            .eq('announcement_id', communicationId)
            .eq('user_id', userId)
            .limit(1);

        isRead = List<Map<String, dynamic>>.from(readsData).isNotEmpty;
      }

      return AppSuccess(
        CommunicationSummary.fromMap(
          Map<String, dynamic>.from(data),
          isRead: isRead,
        ),
      );
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare la comunicazione.',
        code: 'communication_load_error',
      );
    }
  }

  Future<AppResult<String>> createCommunication({
    required CreateCommunicationRequest request,
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
          .from('announcements')
          .insert(request.toInsertMap())
          .select('id')
          .single();

      final communicationId = (data['id'] ?? '').toString();

      if (communicationId.isEmpty) {
        return const AppFailure(
          'Comunicazione creata, ma identificativo non ricevuto.',
          code: 'communication_created_without_id',
        );
      }

      return AppSuccess(communicationId);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile creare la comunicazione.',
        code: 'communication_create_error',
      );
    }
  }

  Future<AppResult<void>> markAsRead({required String communicationId}) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    final user = _client.auth.currentUser;

    if (user == null) {
      return const AppFailure(
        'Devi effettuare l’accesso.',
        code: 'not_authenticated',
      );
    }

    if (communicationId.isEmpty) {
      return const AppFailure(
        'Comunicazione non valida.',
        code: 'invalid_communication_id',
      );
    }

    try {
      await _client.from('announcement_reads').upsert({
        'announcement_id': communicationId,
        'user_id': user.id,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'announcement_id,user_id');

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile segnare la comunicazione come letta.',
        code: 'communication_mark_read_error',
      );
    }
  }
}
