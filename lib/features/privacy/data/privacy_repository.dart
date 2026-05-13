import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/account_deletion_request.dart';

class PrivacyRepository {
  PrivacyRepository();

  static const String _selectColumns =
      'id, user_id, status, reason, requested_at, cancelled_at, completed_at, created_at, updated_at';

  SupabaseClient get _client => SupabaseService.client;

  Future<AppResult<AccountDeletionRequest?>>
  fetchLatestDeletionRequest() async {
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

    try {
      final row = await _fetchLatestRow(user.id);

      if (row == null) {
        return const AppSuccess(null);
      }

      return AppSuccess(AccountDeletionRequest.fromMap(row));
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare le informazioni privacy.',
        code: 'privacy_load_error',
      );
    }
  }

  Future<AppResult<AccountDeletionRequest>> requestAccountDeletion({
    required String reason,
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
        'Devi effettuare l’accesso.',
        code: 'not_authenticated',
      );
    }

    try {
      final existing = await _fetchPendingRow(user.id);

      if (existing != null) {
        return AppSuccess(AccountDeletionRequest.fromMap(existing));
      }

      final now = DateTime.now().toUtc().toIso8601String();

      await _client.from('account_deletion_requests').insert({
        'user_id': user.id,
        'status': 'pending',
        'reason': reason.trim(),
        'requested_at': now,
      });

      final created = await _fetchPendingRow(user.id);

      if (created == null) {
        return const AppFailure(
          'Richiesta creata ma non recuperabile.',
          code: 'privacy_request_not_found',
        );
      }

      return AppSuccess(AccountDeletionRequest.fromMap(created));
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile creare la richiesta di eliminazione account.',
        code: 'privacy_request_error',
      );
    }
  }

  Future<AppResult<AccountDeletionRequest>> cancelDeletionRequest({
    required String requestId,
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
        'Devi effettuare l’accesso.',
        code: 'not_authenticated',
      );
    }

    try {
      final now = DateTime.now().toUtc().toIso8601String();

      await _client
          .from('account_deletion_requests')
          .update({'status': 'cancelled', 'cancelled_at': now})
          .eq('id', requestId)
          .eq('user_id', user.id)
          .eq('status', 'pending');

      final updated = await _fetchLatestRow(user.id);

      if (updated == null) {
        return const AppFailure(
          'Richiesta non trovata.',
          code: 'privacy_request_not_found',
        );
      }

      return AppSuccess(AccountDeletionRequest.fromMap(updated));
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile annullare la richiesta.',
        code: 'privacy_cancel_error',
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchPendingRow(String userId) async {
    final rows = await _client
        .from('account_deletion_requests')
        .select(_selectColumns)
        .eq('user_id', userId)
        .eq('status', 'pending')
        .order('requested_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(rows.first);
  }

  Future<Map<String, dynamic>?> _fetchLatestRow(String userId) async {
    final rows = await _client
        .from('account_deletion_requests')
        .select(_selectColumns)
        .eq('user_id', userId)
        .order('requested_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(rows.first);
  }
}
