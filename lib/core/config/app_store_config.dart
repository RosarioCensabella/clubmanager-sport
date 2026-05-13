class AppStoreConfig {
  const AppStoreConfig._();

  static const String appName = 'ClubManager Sport';

  static const String supportEmail = 'supporto@clubmanagersport.it';

  static const String developerName = 'ClubManager Sport';

  static const String privacyPolicyUrl =
      'https://RosarioCensabella.github.io/clubmanager-sport-legal-pages/privacy-policy.html';

  static const String termsOfServiceUrl =
      'https://RosarioCensabella.github.io/clubmanager-sport-legal-pages/terms-of-service.html';

  static const String accountDeletionRequestUrl =
      'https://RosarioCensabella.github.io/clubmanager-sport-legal-pages/account-deletion.html';

  static bool get hasPublicPrivacyPolicyUrl {
    return privacyPolicyUrl.trim().isNotEmpty;
  }

  static bool get hasPublicTermsUrl {
    return termsOfServiceUrl.trim().isNotEmpty;
  }

  static bool get hasPublicAccountDeletionUrl {
    return accountDeletionRequestUrl.trim().isNotEmpty;
  }
}
