class NotificationPreferences {
  const NotificationPreferences({
    required this.userId,
    required this.pushEnabled,
    required this.eventNotificationsEnabled,
    required this.communicationNotificationsEnabled,
    required this.documentNotificationsEnabled,
    required this.feeNotificationsEnabled,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final bool pushEnabled;
  final bool eventNotificationsEnabled;
  final bool communicationNotificationsEnabled;
  final bool documentNotificationsEnabled;
  final bool feeNotificationsEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory NotificationPreferences.defaults({required String userId}) {
    return NotificationPreferences(
      userId: userId,
      pushEnabled: true,
      eventNotificationsEnabled: true,
      communicationNotificationsEnabled: true,
      documentNotificationsEnabled: true,
      feeNotificationsEnabled: true,
    );
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      userId: (map['user_id'] ?? '').toString(),
      pushEnabled: map['push_enabled'] != false,
      eventNotificationsEnabled: map['event_notifications_enabled'] != false,
      communicationNotificationsEnabled:
          map['communication_notifications_enabled'] != false,
      documentNotificationsEnabled:
          map['document_notifications_enabled'] != false,
      feeNotificationsEnabled: map['fee_notifications_enabled'] != false,
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((map['updated_at'] ?? '').toString()),
    );
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? eventNotificationsEnabled,
    bool? communicationNotificationsEnabled,
    bool? documentNotificationsEnabled,
    bool? feeNotificationsEnabled,
  }) {
    return NotificationPreferences(
      userId: userId,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      eventNotificationsEnabled:
          eventNotificationsEnabled ?? this.eventNotificationsEnabled,
      communicationNotificationsEnabled:
          communicationNotificationsEnabled ??
          this.communicationNotificationsEnabled,
      documentNotificationsEnabled:
          documentNotificationsEnabled ?? this.documentNotificationsEnabled,
      feeNotificationsEnabled:
          feeNotificationsEnabled ?? this.feeNotificationsEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toUpsertMap() {
    return {
      'user_id': userId,
      'push_enabled': pushEnabled,
      'event_notifications_enabled': eventNotificationsEnabled,
      'communication_notifications_enabled': communicationNotificationsEnabled,
      'document_notifications_enabled': documentNotificationsEnabled,
      'fee_notifications_enabled': feeNotificationsEnabled,
    };
  }
}
