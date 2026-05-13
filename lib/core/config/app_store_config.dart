class AppStoreConfig {
  const AppStoreConfig._();

  static const String appName = 'ClubManager Sport';

  static const String supportEmail = 'supporto@clubmanagersport.it';

  static const String developerName = 'ClubManager Sport';

  static const String privacyPolicyUrl = '';

  static const String termsOfServiceUrl = '';

  static const String accountDeletionRequestUrl = '';

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
