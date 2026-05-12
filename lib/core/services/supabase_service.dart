import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_environment.dart';

class SupabaseService {
  const SupabaseService._();

  static bool get isConfigured {
    final config = AppEnvironmentConfig.current;

    return config.supabaseUrl.isNotEmpty && config.supabaseAnonKey.isNotEmpty;
  }

  static Future<void> initialize() async {
    if (!isConfigured) {
      return;
    }

    await Supabase.initialize(
      url: AppEnvironmentConfig.current.supabaseUrl,
      anonKey: AppEnvironmentConfig.current.supabaseAnonKey,
    );
  }

  static SupabaseClient get client {
    if (!isConfigured) {
      throw StateError(
        'Supabase non configurato. Avvia l’app con SUPABASE_URL e SUPABASE_ANON_KEY.',
      );
    }

    return Supabase.instance.client;
  }
}
