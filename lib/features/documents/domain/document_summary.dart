class DocumentSummary {
  const DocumentSummary({
    required this.id,
    required this.clubId,
    required this.title,
    required this.category,
    required this.scope,
    required this.status,
    required this.storageBucket,
    required this.filePath,
    required this.fileName,
    required this.createdAt,
    this.description,
    this.teamId,
    this.teamName,
    this.athleteProfileId,
    this.athleteName,
    this.mimeType,
    this.sizeBytes,
    this.expiresAt,
  });

  final String id;
  final String clubId;
  final String? teamId;
  final String? teamName;
  final String? athleteProfileId;
  final String? athleteName;
  final String title;
  final String? description;
  final String category;
  final String scope;
  final String status;
  final String storageBucket;
  final String filePath;
  final String fileName;
  final String? mimeType;
  final int? sizeBytes;
  final DateTime? expiresAt;
  final DateTime createdAt;

  factory DocumentSummary.fromMap(
    Map<String, dynamic> map, {
    String? teamName,
    String? athleteName,
  }) {
    return DocumentSummary(
      id: (map['id'] ?? '').toString(),
      clubId: (map['club_id'] ?? '').toString(),
      teamId: map['team_id']?.toString(),
      teamName: teamName,
      athleteProfileId: map['athlete_profile_id']?.toString(),
      athleteName: athleteName,
      title: (map['title'] ?? 'Documento').toString(),
      description: map['description']?.toString(),
      category: (map['category'] ?? 'other').toString(),
      scope: (map['scope'] ?? 'club').toString(),
      status: (map['status'] ?? 'active').toString(),
      storageBucket: (map['storage_bucket'] ?? 'club-documents').toString(),
      filePath: (map['file_path'] ?? '').toString(),
      fileName: (map['file_name'] ?? '').toString(),
      mimeType: map['mime_type']?.toString(),
      sizeBytes: int.tryParse((map['size_bytes'] ?? '').toString()),
      expiresAt: DateTime.tryParse((map['expires_at'] ?? '').toString()),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  String get categoryLabel {
    switch (category) {
      case 'medical_certificate':
        return 'Certificato medico';
      case 'identity_document':
        return 'Documento identità';
      case 'membership':
        return 'Tesseramento';
      case 'privacy':
        return 'Privacy';
      case 'payment':
        return 'Pagamento';
      default:
        return 'Altro';
    }
  }

  String get scopeLabel {
    switch (scope) {
      case 'team':
        return teamName ?? 'Squadra';
      case 'athlete':
        return athleteName ?? 'Atleta';
      default:
        return 'Club';
    }
  }

  bool get hasDeadline => expiresAt != null;

  bool get isExpired {
    final expiry = expiresAt;

    if (expiry == null) {
      return false;
    }

    final today = DateTime.now();

    return DateTime(
      expiry.year,
      expiry.month,
      expiry.day,
    ).isBefore(DateTime(today.year, today.month, today.day));
  }

  bool get isExpiringSoon {
    final expiry = expiresAt;

    if (expiry == null || isExpired) {
      return false;
    }

    return expiry.difference(DateTime.now()).inDays <= 30;
  }
}
