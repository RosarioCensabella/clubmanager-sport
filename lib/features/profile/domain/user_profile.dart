class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.avatarUrl,
    required this.preferredLanguage,
    required this.marketingConsent,
    required this.onboardingCompleted,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String avatarUrl;
  final String preferredLanguage;
  final bool marketingConsent;
  final bool onboardingCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.empty({required String id, required String email}) {
    return UserProfile(
      id: id,
      email: email,
      fullName: '',
      phoneNumber: '',
      avatarUrl: '',
      preferredLanguage: 'it',
      marketingConsent: false,
      onboardingCompleted: false,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: (map['id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      phoneNumber: (map['phone_number'] ?? '').toString(),
      avatarUrl: (map['avatar_url'] ?? '').toString(),
      preferredLanguage: (map['preferred_language'] ?? 'it').toString(),
      marketingConsent: map['marketing_consent'] == true,
      onboardingCompleted: map['onboarding_completed'] == true,
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((map['updated_at'] ?? '').toString()),
    );
  }

  String get displayName {
    final trimmed = fullName.trim();

    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    if (email.trim().isNotEmpty) {
      return email.trim();
    }

    return 'Utente';
  }

  String get initials {
    final name = displayName.trim();

    if (name.isEmpty) {
      return '?';
    }

    final parts = name.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return _firstLetter(parts.first).toUpperCase();
    }

    final first = _firstLetter(parts.first);
    final last = _firstLetter(parts.last);
    final result = '$first$last'.trim();

    if (result.isEmpty) {
      return '?';
    }

    return result.toUpperCase();
  }

  String _firstLetter(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return '';
    }

    return trimmed.substring(0, 1);
  }
}
