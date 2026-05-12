class CreateCommunicationRequest {
  const CreateCommunicationRequest({
    required this.clubId,
    required this.title,
    required this.body,
    required this.priority,
    required this.createdBy,
    required this.allowComments,
    required this.sendPush,
    this.teamId,
  });

  final String clubId;
  final String? teamId;
  final String title;
  final String body;
  final String priority;
  final String createdBy;
  final bool allowComments;
  final bool sendPush;

  Map<String, dynamic> toInsertMap() {
    final now = DateTime.now().toUtc().toIso8601String();
    final visibility = teamId == null || teamId!.trim().isEmpty
        ? 'club'
        : 'team';

    return {
      'club_id': clubId,
      'team_id': _nullableTrim(teamId),
      'title': title.trim(),
      'body': body.trim(),
      'content': body.trim(),
      'priority': priority,
      'visibility': visibility,
      'status': 'published',
      'allow_comments': allowComments,
      'send_push': sendPush,
      'pinned': priority == 'urgent',
      'created_by': createdBy,
      'published_at': now,
      'publish_at': now,
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
