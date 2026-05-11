enum AppEnvironment {
  development,
  staging,
  production,
}

class AppEnvironmentConfig {
  const AppEnvironmentConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.sentryDsn,
  });

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String sentryDsn;

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProduction => environment == AppEnvironment.production;

  static const AppEnvironmentConfig current = AppEnvironmentConfig(
    environment: AppEnvironment.development,
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    sentryDsn: String.fromEnvironment('SENTRY_DSN'),
  );
}