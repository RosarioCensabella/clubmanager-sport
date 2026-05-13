class FeeSummary {
  const FeeSummary({
    required this.id,
    required this.clubId,
    required this.title,
    required this.scope,
    required this.amountCents,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.assignmentsCount,
    required this.paidCount,
    required this.unpaidCount,
    this.description,
    this.teamId,
    this.teamName,
    this.dueDate,
  });

  final String id;
  final String clubId;
  final String? teamId;
  final String? teamName;
  final String title;
  final String? description;
  final String scope;
  final int amountCents;
  final String currency;
  final DateTime? dueDate;
  final String status;
  final DateTime createdAt;
  final int assignmentsCount;
  final int paidCount;
  final int unpaidCount;

  factory FeeSummary.fromMap(
    Map<String, dynamic> map, {
    String? teamName,
    int assignmentsCount = 0,
    int paidCount = 0,
    int unpaidCount = 0,
  }) {
    return FeeSummary(
      id: (map['id'] ?? '').toString(),
      clubId: (map['club_id'] ?? '').toString(),
      teamId: map['team_id']?.toString(),
      teamName: teamName,
      title: (map['title'] ?? '').toString(),
      description: map['description']?.toString(),
      scope: (map['scope'] ?? 'club').toString(),
      amountCents: int.tryParse((map['amount_cents'] ?? '0').toString()) ?? 0,
      currency: (map['currency'] ?? 'EUR').toString(),
      dueDate: DateTime.tryParse((map['due_date'] ?? '').toString()),
      status: (map['status'] ?? 'active').toString(),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
      assignmentsCount: assignmentsCount,
      paidCount: paidCount,
      unpaidCount: unpaidCount,
    );
  }

  String get amountLabel {
    final euros = amountCents / 100;

    return '${euros.toStringAsFixed(2).replaceAll('.', ',')} $currency';
  }

  String get scopeLabel {
    switch (scope) {
      case 'team':
        return teamName ?? 'Squadra';
      case 'athlete':
        return 'Atleti selezionati';
      default:
        return 'Tutto il club';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'archived':
        return 'Archiviata';
      default:
        return 'Attiva';
    }
  }

  String get dueDateLabel {
    final value = dueDate;

    if (value == null) {
      return 'Nessuna scadenza';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');

    return '$day/$month/$year';
  }
}
