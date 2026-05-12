class CreateClubRequest {
  const CreateClubRequest({
    required this.name,
    required this.sportPrimary,
    required this.city,
    this.address,
    this.email,
    this.phone,
    this.website,
    this.fiscalCode,
    this.season,
  });

  final String name;
  final String sportPrimary;
  final String city;
  final String? address;
  final String? email;
  final String? phone;
  final String? website;
  final String? fiscalCode;
  final String? season;

  Map<String, dynamic> toInsertMap({required String ownerUserId}) {
    return {
      'owner_user_id': ownerUserId,
      'name': name.trim(),
      'sport_primary': sportPrimary.trim(),
      'city': city.trim(),
      'address': _nullableTrim(address),
      'email': _nullableTrim(email),
      'phone': _nullableTrim(phone),
      'website': _nullableTrim(website),
      'fiscal_code': _nullableTrim(fiscalCode),
      'season': _nullableTrim(season),
    };
  }

  static String? _nullableTrim(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
