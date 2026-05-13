class CreateFeeRequest {
  const CreateFeeRequest({
    required this.clubId,
    required this.title,
    required this.amountCents,
    required this.currency,
    required this.scope,
    required this.athleteProfileIds,
    required this.createdBy,
    this.description,
    this.teamId,
    this.dueDate,
  });

  final String clubId;
  final String title;
  final String? description;
  final int amountCents;
  final String currency;
  final String scope;
  final String? teamId;
  final List<String> athleteProfileIds;
  final DateTime? dueDate;
  final String createdBy;

  double get amountDecimal => amountCents / 100;

  Map<String, dynamic> toFeeInsertMap() {
    return {
      'club_id': clubId,
      'team_id': _nullableTrim(teamId),
      'title': title.trim(),
      'description': _nullableTrim(description),
      'scope': scope,
      'amount': amountDecimal,
      'amount_cents': amountCents,
      'currency': currency,
      'due_date': _dateToString(dueDate),
      'status': 'active',
      'created_by': createdBy,
    };
  }

  List<Map<String, dynamic>> toAssignmentRows({required String feeId}) {
    return athleteProfileIds
        .map(
          (athleteId) => {
            'fee_id': feeId,
            'club_id': clubId,
            'athlete_profile_id': athleteId,
            'amount_cents': amountCents,
            'amount_due': amountDecimal,
            'amount_paid': 0,
            'currency': currency,
            'status': 'unpaid',
            'due_date': _dateToString(dueDate),
            'created_by': createdBy,
            'updated_by': createdBy,
          },
        )
        .toList(growable: false);
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
