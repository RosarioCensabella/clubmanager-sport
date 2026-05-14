class UpdateClubRequest {
  const UpdateClubRequest({
    required this.name,
    required this.sportPrimary,
    required this.city,
    this.address,
    this.email,
    this.phone,
    this.website,
    this.fiscalCode,
    this.season,
    this.primaryColor,
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
  final String? primaryColor;

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name.trim(),
      'sport_primary': sportPrimary.trim(),
      'city': city.trim(),
      'address': _nullableTrim(address),
      'email': _nullableTrim(email),
      'phone': _nullableTrim(phone),
      'website': _nullableTrim(website),
      'fiscal_code': _nullableTrim(fiscalCode),
      'season': _nullableTrim(season),
      'primary_color': _nullableTrim(primaryColor),
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
