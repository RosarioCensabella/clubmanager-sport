class ClubDetail {
  const ClubDetail({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.sportPrimary,
    required this.city,
    required this.createdAt,
    required this.updatedAt,
    this.logoUrl,
    this.primaryColor,
    this.address,
    this.email,
    this.phone,
    this.website,
    this.fiscalCode,
    this.season,
    this.subscriptionPlan,
    this.subscriptionStatus,
    this.deletedAt,
    this.archivedAt,
    this.archivedBy,
    this.archiveReason,
  });

  final String id;
  final String ownerUserId;
  final String name;
  final String sportPrimary;
  final String city;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? logoUrl;
  final String? primaryColor;
  final String? address;
  final String? email;
  final String? phone;
  final String? website;
  final String? fiscalCode;
  final String? season;
  final String? subscriptionPlan;
  final String? subscriptionStatus;
  final DateTime? deletedAt;
  final DateTime? archivedAt;
  final String? archivedBy;
  final String? archiveReason;

  bool get isArchived => deletedAt != null || archivedAt != null;

  factory ClubDetail.fromMap(Map<String, dynamic> map) {
    return ClubDetail(
      id: (map['id'] ?? '').toString(),
      ownerUserId: (map['owner_user_id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      sportPrimary: (map['sport_primary'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      logoUrl: map['logo_url']?.toString(),
      primaryColor: map['primary_color']?.toString(),
      address: map['address']?.toString(),
      email: map['email']?.toString(),
      phone: map['phone']?.toString(),
      website: map['website']?.toString(),
      fiscalCode: map['fiscal_code']?.toString(),
      season: map['season']?.toString(),
      subscriptionPlan: map['subscription_plan']?.toString(),
      subscriptionStatus: map['subscription_status']?.toString(),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse((map['updated_at'] ?? '').toString()) ??
          DateTime.now(),
      deletedAt: DateTime.tryParse((map['deleted_at'] ?? '').toString()),
      archivedAt: DateTime.tryParse((map['archived_at'] ?? '').toString()),
      archivedBy: map['archived_by']?.toString(),
      archiveReason: map['archive_reason']?.toString(),
    );
  }
}
