import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/auth_user.dart';

class AuthRepository {
  AuthRepository();

  SupabaseClient get _client => SupabaseService.client;

  bool get isConfigured => SupabaseService.isConfigured;

  AppAuthUser? get currentUser {
    if (!isConfigured) {
      return null;
    }

    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    return AppAuthUser(id: user.id, email: user.email ?? '');
  }

  Stream<AppAuthUser?> authStateChanges() {
    if (!isConfigured) {
      return Stream<AppAuthUser?>.value(null);
    }

    return _client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;

      if (user == null) {
        return null;
      }

      return AppAuthUser(id: user.id, email: user.email ?? '');
    });
  }

  Future<AppResult<AppAuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (!isConfigured) {
      return const AppFailure(
        'Supabase non è configurato. Avvia l’app con SUPABASE_URL e SUPABASE_ANON_KEY.',
        code: 'supabase_not_configured',
      );
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;

      if (user == null) {
        return const AppFailure(
          'Login non riuscito. Controlla le credenziali e riprova.',
          code: 'login_failed',
        );
      }

      return AppSuccess(
        AppAuthUser(id: user.id, email: user.email ?? email.trim()),
      );
    } on AuthException catch (error) {
      return AppFailure(_mapAuthError(error), code: error.statusCode);
    } catch (_) {
      return const AppFailure(
        'Si è verificato un errore durante il login.',
        code: 'unknown_login_error',
      );
    }
  }

  Future<AppResult<AppAuthUser?>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    if (!isConfigured) {
      return const AppFailure(
        'Supabase non è configurato. Avvia l’app con SUPABASE_URL e SUPABASE_ANON_KEY.',
        code: 'supabase_not_configured',
      );
    }

    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'first_name': firstName.trim(), 'last_name': lastName.trim()},
      );

      final user = response.user;

      if (user == null) {
        return const AppSuccess(null);
      }

      return AppSuccess(
        AppAuthUser(id: user.id, email: user.email ?? email.trim()),
      );
    } on AuthException catch (error) {
      return AppFailure(_mapAuthError(error), code: error.statusCode);
    } catch (_) {
      return const AppFailure(
        'Si è verificato un errore durante la registrazione.',
        code: 'unknown_signup_error',
      );
    }
  }

  Future<AppResult<void>> sendPasswordResetEmail({
    required String email,
  }) async {
    if (!isConfigured) {
      return const AppFailure(
        'Supabase non è configurato. Avvia l’app con SUPABASE_URL e SUPABASE_ANON_KEY.',
        code: 'supabase_not_configured',
      );
    }

    try {
      await _client.auth.resetPasswordForEmail(email.trim());

      return const AppSuccess(null);
    } on AuthException catch (error) {
      return AppFailure(_mapAuthError(error), code: error.statusCode);
    } catch (_) {
      return const AppFailure(
        'Si è verificato un errore durante il recupero password.',
        code: 'unknown_reset_error',
      );
    }
  }

  Future<AppResult<void>> signOut() async {
    if (!isConfigured) {
      return const AppSuccess(null);
    }

    try {
      await _client.auth.signOut();

      return const AppSuccess(null);
    } on AuthException catch (error) {
      return AppFailure(_mapAuthError(error), code: error.statusCode);
    } catch (_) {
      return const AppFailure(
        'Si è verificato un errore durante il logout.',
        code: 'unknown_logout_error',
      );
    }
  }

  String _mapAuthError(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Email o password non corretti.';
    }

    if (message.contains('email not confirmed')) {
      return 'Devi confermare la tua email prima di accedere.';
    }

    if (message.contains('user already registered')) {
      return 'Esiste già un account con questa email.';
    }

    if (message.contains('password')) {
      return 'La password non rispetta i requisiti richiesti.';
    }

    if (message.contains('email')) {
      return 'Controlla che l’indirizzo email sia corretto.';
    }

    return error.message;
  }
}
