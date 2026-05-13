import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/notification_preferences.dart';

class SettingsRepository {
  SettingsRepository();

  static const String _selectColumns =
      'user_id, push_enabled, event_notifications_enabled, communication_notifications_enabled, document_notifications_enabled, fee_notifications_enabled, created_at, updated_at';

  SupabaseClient get _client => SupabaseService.client;

  Future<AppResult<NotificationPreferences>>
  fetchNotificationPreferences() async {
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
      final existing = await _fetchLatestPreferencesRow(user.id);

      if (existing != null) {
        return AppSuccess(NotificationPreferences.fromMap(existing));
      }

      final preferences = NotificationPreferences.defaults(userId: user.id);

      await _client
          .from('notification_preferences')
          .upsert(preferences.toUpsertMap(), onConflict: 'user_id');

      await NotificationService.instance.refreshTokenRegistration();

      final created = await _fetchLatestPreferencesRow(user.id);

      if (created == null) {
        return AppSuccess(preferences);
      }

      return AppSuccess(NotificationPreferences.fromMap(created));
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare le impostazioni.',
        code: 'settings_load_error',
      );
    }
  }

  Future<AppResult<NotificationPreferences>> updateNotificationPreferences({
    required NotificationPreferences preferences,
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

    if (preferences.userId != user.id) {
      return const AppFailure(
        'Non puoi modificare impostazioni di un altro utente.',
        code: 'settings_user_mismatch',
      );
    }

    try {
      await _client
          .from('notification_preferences')
          .upsert(preferences.toUpsertMap(), onConflict: 'user_id');

      await _syncPushTokens(
        userId: user.id,
        pushEnabled: preferences.pushEnabled,
      );

      final updated = await _fetchLatestPreferencesRow(user.id);

      if (updated == null) {
        return AppSuccess(preferences);
      }

      return AppSuccess(NotificationPreferences.fromMap(updated));
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile salvare le impostazioni.',
        code: 'settings_update_error',
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchLatestPreferencesRow(
    String userId,
  ) async {
    final rows = await _client
        .from('notification_preferences')
        .select(_selectColumns)
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(rows.first);
  }

  Future<void> _syncPushTokens({
    required String userId,
    required bool pushEnabled,
  }) async {
    if (pushEnabled) {
      await NotificationService.instance.refreshTokenRegistration();
      return;
    }

    final now = DateTime.now().toUtc().toIso8601String();

    await _client
        .from('push_tokens')
        .update({'is_active': false, 'last_seen_at': now})
        .eq('user_id', userId);
  }
}
