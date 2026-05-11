class AppConstants {
  const AppConstants._();

  static const String appName = 'ClubManager Sport';

  static const String defaultLocale = 'it_IT';

  static const int defaultPageSize = 25;
  static const int maxUploadFileSizeMb = 10;

  static const Duration defaultAnimationDuration = Duration(milliseconds: 250);
  static const Duration networkTimeout = Duration(seconds: 20);

  static const String privacyPolicyPath = '/privacy-policy';
  static const String termsOfServicePath = '/terms-of-service';
  static const String deleteAccountPath = '/delete-account';

  static const List<String> supportedEventTypes = [
    'allenamento',
    'partita',
    'torneo',
    'riunione',
    'visita_medica',
    'evento_sociale',
    'scadenza_pagamento',
    'altro',
  ];

  static const List<String> supportedClubRoles = [
    'owner',
    'admin',
    'team_manager',
    'coach',
    'athlete',
    'parent',
    'staff',
  ];
}
