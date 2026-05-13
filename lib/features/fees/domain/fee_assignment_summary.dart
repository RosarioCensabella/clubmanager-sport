import '../../athletes/domain/athlete_summary.dart';

class FeeAssignmentSummary {
  const FeeAssignmentSummary({
    required this.id,
    required this.feeId,
    required this.clubId,
    required this.athleteProfileId,
    required this.amountCents,
    required this.amountDue,
    required this.amountPaid,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.athlete,
    this.dueDate,
    this.paidAt,
    this.paymentReference,
    this.notes,
  });

  final String id;
  final String feeId;
  final String clubId;
  final String athleteProfileId;
  final int amountCents;
  final double amountDue;
  final double amountPaid;
  final String currency;
  final String status;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? paymentReference;
  final String? notes;
  final DateTime createdAt;
  final AthleteSummary athlete;

  factory FeeAssignmentSummary.fromMap(Map<String, dynamic> map) {
    final rawAthlete = map['athlete_profiles'];
    final athleteMap = rawAthlete is Map
        ? Map<String, dynamic>.from(rawAthlete)
        : <String, dynamic>{};

    final amountDue =
        double.tryParse((map['amount_due'] ?? '').toString()) ??
        ((int.tryParse((map['amount_cents'] ?? '0').toString()) ?? 0) / 100);

    final amountPaid =
        double.tryParse((map['amount_paid'] ?? '0').toString()) ?? 0;

    final amountCents =
        int.tryParse((map['amount_cents'] ?? '').toString()) ??
        (amountDue * 100).round();

    return FeeAssignmentSummary(
      id: (map['id'] ?? '').toString(),
      feeId: (map['fee_id'] ?? '').toString(),
      clubId: (map['club_id'] ?? '').toString(),
      athleteProfileId: (map['athlete_profile_id'] ?? '').toString(),
      amountCents: amountCents,
      amountDue: amountDue,
      amountPaid: amountPaid,
      currency: (map['currency'] ?? 'EUR').toString(),
      status: (map['status'] ?? 'unpaid').toString(),
      dueDate: DateTime.tryParse((map['due_date'] ?? '').toString()),
      paidAt: DateTime.tryParse((map['paid_at'] ?? '').toString()),
      paymentReference: map['payment_reference']?.toString(),
      notes: map['notes']?.toString(),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
      athlete: AthleteSummary.fromMap(athleteMap),
    );
  }

  double get remainingAmount {
    final remaining = amountDue - amountPaid;

    if (remaining <= 0) {
      return 0;
    }

    return remaining;
  }

  String get amountLabel {
    return '${amountDue.toStringAsFixed(2).replaceAll('.', ',')} $currency';
  }

  String get paidLabel {
    return '${amountPaid.toStringAsFixed(2).replaceAll('.', ',')} $currency';
  }

  String get remainingLabel {
    return '${remainingAmount.toStringAsFixed(2).replaceAll('.', ',')} $currency';
  }

  String get statusLabel {
    switch (status) {
      case 'paid':
        return 'Pagata';
      case 'partial':
        return 'Parziale';
      case 'waived':
        return 'Esonerata';
      case 'overdue':
        return 'Scaduta';
      default:
        return 'Da pagare';
    }
  }

  bool get isPaid => status == 'paid';

  bool get isUnpaid => status == 'unpaid';

  bool get isPartial => status == 'partial';

  bool get isWaived => status == 'waived';

  bool get isOverdue => status == 'overdue';
}
