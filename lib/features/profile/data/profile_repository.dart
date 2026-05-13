import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/user_profile.dart';

class ProfileRepository {
  ProfileRepository();

  SupabaseClient get _client => SupabaseService.client;

  Future<AppResult<UserProfile>> fetchCurrentProfile() async {
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
      final data = await _client
          .from('profiles')
          .select(
            'id, email, full_name, phone_number, avatar_url, preferred_language, marketing_consent, onboarding_completed, created_at, updated_at',
          )
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        final profile = UserProfile.empty(id: user.id, email: user.email ?? '');

        await _client.from('profiles').insert({
          'id': profile.id,
          'email': profile.email,
          'full_name': profile.fullName,
          'phone_number': profile.phoneNumber,
          'preferred_language': profile.preferredLanguage,
          'marketing_consent': profile.marketingConsent,
          'onboarding_completed': profile.onboardingCompleted,
        });

        return AppSuccess(profile);
      }

      return AppSuccess(UserProfile.fromMap(Map<String, dynamic>.from(data)));
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare il profilo.',
        code: 'profile_load_error',
      );
    }
  }

  Future<AppResult<UserProfile>> updateCurrentProfile({
    required String fullName,
    required String phoneNumber,
    required bool marketingConsent,
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
      final data = await _client
          .from('profiles')
          .upsert({
            'id': user.id,
            'email': user.email ?? '',
            'full_name': fullName.trim(),
            'phone_number': phoneNumber.trim(),
            'preferred_language': 'it',
            'marketing_consent': marketingConsent,
            'onboarding_completed': true,
          })
          .select(
            'id, email, full_name, phone_number, avatar_url, preferred_language, marketing_consent, onboarding_completed, created_at, updated_at',
          )
          .single();

      await NotificationService.instance.refreshTokenRegistration();

      return AppSuccess(UserProfile.fromMap(Map<String, dynamic>.from(data)));
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile aggiornare il profilo.',
        code: 'profile_update_error',
      );
    }
  }

  Future<AppResult<void>> signOut() async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    try {
      await _client.auth.signOut();

      return const AppSuccess(null);
    } on AuthException catch (error) {
      return AppFailure(error.message, code: error.statusCode);
    } catch (_) {
      return const AppFailure(
        'Impossibile uscire dall’account.',
        code: 'profile_sign_out_error',
      );
    }
  }
}
