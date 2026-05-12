class CommunicationSummary {
  const CommunicationSummary({
    required this.id,
    required this.clubId,
    required this.title,
    required this.body,
    required this.priority,
    required this.visibility,
    required this.status,
    required this.allowComments,
    required this.sendPush,
    required this.pinned,
    required this.createdAt,
    required this.isRead,
    this.teamId,
    this.teamName,
    this.createdBy,
    this.publishedAt,
    this.expiresAt,
  });

  final String id;
  final String clubId;
  final String? teamId;
  final String? teamName;
  final String title;
  final String body;
  final String priority;
  final String visibility;
  final String status;
  final bool allowComments;
  final bool sendPush;
  final bool pinned;
  final String? createdBy;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final bool isRead;

  factory CommunicationSummary.fromMap(
    Map<String, dynamic> map, {
    bool isRead = false,
  }) {
    final rawTeam = map['teams'];
    final teamMap = rawTeam is Map
        ? Map<String, dynamic>.from(rawTeam)
        : <String, dynamic>{};

    final body = (map['body'] ?? map['content'] ?? '').toString();

    return CommunicationSummary(
      id: (map['id'] ?? '').toString(),
      clubId: (map['club_id'] ?? '').toString(),
      teamId: map['team_id']?.toString(),
      teamName: teamMap['name']?.toString(),
      title: (map['title'] ?? '').toString(),
      body: body,
      priority: (map['priority'] ?? 'normal').toString(),
      visibility: (map['visibility'] ?? 'club').toString(),
      status: (map['status'] ?? 'published').toString(),
      allowComments: map['allow_comments'] != false,
      sendPush: map['send_push'] == true,
      pinned: map['pinned'] == true,
      createdBy: map['created_by']?.toString(),
      publishedAt: DateTime.tryParse(
        (map['published_at'] ?? map['publish_at'] ?? '').toString(),
      ),
      expiresAt: DateTime.tryParse((map['expires_at'] ?? '').toString()),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
      isRead: isRead,
    );
  }

  String get priorityLabel {
    switch (priority) {
      case 'urgent':
        return 'Urgente';
      case 'important':
        return 'Importante';
      default:
        return 'Normale';
    }
  }

  String get visibilityLabel {
    if (teamId != null && teamId!.isNotEmpty) {
      return teamName ?? 'Squadra';
    }

    return 'Tutto il club';
  }

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Bozza';
      case 'archived':
        return 'Archiviata';
      default:
        return 'Pubblicata';
    }
  }
}
