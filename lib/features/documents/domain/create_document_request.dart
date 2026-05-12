class CreateDocumentRequest {
  const CreateDocumentRequest({
    required this.clubId,
    required this.title,
    required this.category,
    required this.scope,
    required this.fileName,
    required this.filePath,
    required this.storageBucket,
    required this.uploadedBy,
    this.description,
    this.teamId,
    this.athleteProfileId,
    this.mimeType,
    this.sizeBytes,
    this.expiresAt,
  });

  final String clubId;
  final String? teamId;
  final String? athleteProfileId;
  final String title;
  final String? description;
  final String category;
  final String scope;
  final String fileName;
  final String filePath;
  final String storageBucket;
  final String? mimeType;
  final int? sizeBytes;
  final DateTime? expiresAt;
  final String uploadedBy;

  Map<String, dynamic> toInsertMap() {
    return {
      'club_id': clubId,
      'team_id': _nullableTrim(teamId),
      'athlete_profile_id': _nullableTrim(athleteProfileId),
      'title': title.trim(),
      'description': _nullableTrim(description),

      // Compatibilità con lo schema esistente.
      // Nel database remoto esiste una colonna obbligatoria "type".
      'type': category,

      // Nuova classificazione usata dalla UI della Fase 19.
      'category': category,
      'scope': scope,
      'status': 'active',
      'storage_bucket': storageBucket,
      'file_path': filePath,
      'file_name': fileName,
      'mime_type': _nullableTrim(mimeType),
      'size_bytes': sizeBytes,
      'expires_at': _dateToString(expiresAt),
      'uploaded_by': uploadedBy,
      'created_by': uploadedBy,
    };
  }

  static String? _nullableTrim(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  static String? _dateToString(DateTime? value) {
    if (value == null) {
      return null;
    }

    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
