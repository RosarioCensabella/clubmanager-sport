class ClubSummary {
  const ClubSummary({
    required this.id,
    required this.name,
    required this.sportPrimary,
    required this.city,
    this.logoUrl,
    this.primaryColor,
  });

  final String id;
  final String name;
  final String sportPrimary;
  final String city;
  final String? logoUrl;
  final String? primaryColor;

  factory ClubSummary.fromMap(Map<String, dynamic> map) {
    return ClubSummary(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      sportPrimary: (map['sport_primary'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      logoUrl: map['logo_url']?.toString(),
      primaryColor: map['primary_color']?.toString(),
    );
  }
}
