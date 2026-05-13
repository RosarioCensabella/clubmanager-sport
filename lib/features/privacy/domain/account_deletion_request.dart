class AccountDeletionRequest {
  const AccountDeletionRequest({
    required this.id,
    required this.userId,
    required this.status,
    required this.reason,
    this.requestedAt,
    this.cancelledAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String status;
  final String reason;
  final DateTime? requestedAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AccountDeletionRequest.fromMap(Map<String, dynamic> map) {
    return AccountDeletionRequest(
      id: (map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      reason: (map['reason'] ?? '').toString(),
      requestedAt: DateTime.tryParse((map['requested_at'] ?? '').toString()),
      cancelledAt: DateTime.tryParse((map['cancelled_at'] ?? '').toString()),
      completedAt: DateTime.tryParse((map['completed_at'] ?? '').toString()),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((map['updated_at'] ?? '').toString()),
    );
  }

  bool get isPending => status == 'pending';

  bool get isCancelled => status == 'cancelled';

  bool get isCompleted => status == 'completed';

  bool get isRejected => status == 'rejected';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'In attesa';
      case 'cancelled':
        return 'Annullata';
      case 'completed':
        return 'Completata';
      case 'rejected':
        return 'Rifiutata';
      default:
        return 'Sconosciuta';
    }
  }

  String get requestedAtLabel {
    return _formatDateTime(requestedAt);
  }

  String get updatedAtLabel {
    return _formatDateTime(updatedAt);
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Non disponibile';
    }

    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
