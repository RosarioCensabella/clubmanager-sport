import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/create_fee_request.dart';
import '../domain/fee_assignment_summary.dart';
import '../domain/fee_summary.dart';

class FeeRepository {
  FeeRepository();

  SupabaseClient get _client => SupabaseService.client;

  String? currentUserId() {
    if (!SupabaseService.isConfigured) {
      return null;
    }

    return _client.auth.currentUser?.id;
  }

  Future<AppResult<List<FeeSummary>>> fetchFeesForClub({
    required String clubId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (clubId.isEmpty) {
      return const AppFailure(
        'Nessun club attivo selezionato.',
        code: 'active_club_missing',
      );
    }

    try {
      final data = await _client
          .from('fees')
          .select(
            'id, club_id, team_id, title, description, scope, amount, amount_cents, currency, due_date, status, created_at',
          )
          .eq('club_id', clubId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(data);

      final feeIds = rows
          .map((row) => (row['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);

      final teamNames = await _fetchTeamNames(rows);
      final counters = await _fetchAssignmentCounters(feeIds);

      final fees = rows
          .map((row) {
            final feeId = (row['id'] ?? '').toString();
            final teamId = row['team_id']?.toString();
            final counter = counters[feeId] ?? const _FeeCounter();

            return FeeSummary.fromMap(
              row,
              teamName: teamId == null ? null : teamNames[teamId],
              assignmentsCount: counter.total,
              paidCount: counter.paid,
              unpaidCount: counter.unpaid,
            );
          })
          .toList(growable: false);

      return AppSuccess(fees);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare le quote.',
        code: 'fees_load_error',
      );
    }
  }

  Future<AppResult<FeeSummary>> fetchFeeById({required String feeId}) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (feeId.isEmpty) {
      return const AppFailure('Quota non valida.', code: 'invalid_fee_id');
    }

    try {
      final data = await _client
          .from('fees')
          .select(
            'id, club_id, team_id, title, description, scope, amount, amount_cents, currency, due_date, status, created_at',
          )
          .eq('id', feeId)
          .isFilter('deleted_at', null)
          .single();

      final row = Map<String, dynamic>.from(data);
      final counters = await _fetchAssignmentCounters([feeId]);
      final counter = counters[feeId] ?? const _FeeCounter();

      final teamNames = await _fetchTeamNames([row]);
      final teamId = row['team_id']?.toString();

      return AppSuccess(
        FeeSummary.fromMap(
          row,
          teamName: teamId == null ? null : teamNames[teamId],
          assignmentsCount: counter.total,
          paidCount: counter.paid,
          unpaidCount: counter.unpaid,
        ),
      );
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare la quota.',
        code: 'fee_load_error',
      );
    }
  }

  Future<AppResult<List<FeeAssignmentSummary>>> fetchAssignmentsForFee({
    required String feeId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (feeId.isEmpty) {
      return const AppFailure('Quota non valida.', code: 'invalid_fee_id');
    }

    try {
      final data = await _client
          .from('fee_assignments')
          .select(
            'id, fee_id, club_id, athlete_profile_id, amount_cents, amount_due, amount_paid, currency, status, due_date, paid_at, payment_reference, notes, created_at, athlete_profiles(id, club_id, user_id, team_id, first_name, last_name, date_of_birth, jersey_number, sport_role, active, medical_certificate_status, medical_certificate_expiry, staff_notes, teams(id, name))',
          )
          .eq('fee_id', feeId)
          .isFilter('deleted_at', null)
          .order('created_at');

      final rows = List<Map<String, dynamic>>.from(data);

      final assignments = rows
          .map(FeeAssignmentSummary.fromMap)
          .where((assignment) => assignment.athlete.id.isNotEmpty)
          .toList(growable: false);

      return AppSuccess(assignments);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare le assegnazioni quota.',
        code: 'fee_assignments_load_error',
      );
    }
  }

  Future<AppResult<String>> createFeeWithAssignments({
    required CreateFeeRequest request,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (request.athleteProfileIds.isEmpty) {
      return const AppFailure(
        'Seleziona almeno un atleta.',
        code: 'no_athletes_selected',
      );
    }

    String? createdFeeId;

    try {
      final feeData = await _client
          .from('fees')
          .insert(request.toFeeInsertMap())
          .select('id')
          .single();

      createdFeeId = (feeData['id'] ?? '').toString();

      if (createdFeeId.isEmpty) {
        return const AppFailure(
          'Quota creata, ma identificativo non ricevuto.',
          code: 'fee_created_without_id',
        );
      }

      final rows = request.toAssignmentRows(feeId: createdFeeId);

      await _client
          .from('fee_assignments')
          .upsert(rows, onConflict: 'fee_id,athlete_profile_id');

      return AppSuccess(createdFeeId);
    } on PostgrestException catch (error) {
      await _softDeleteCreatedFee(createdFeeId);

      return AppFailure(error.message, code: error.code);
    } catch (_) {
      await _softDeleteCreatedFee(createdFeeId);

      return const AppFailure(
        'Impossibile creare la quota.',
        code: 'fee_create_error',
      );
    }
  }

  Future<AppResult<void>> updateAssignmentStatus({
    required String assignmentId,
    required String status,
    required double amountDue,
    double? amountPaid,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    final user = _client.auth.currentUser;

    if (user == null) {
      return const AppFailure(
        'Devi effettuare l’accesso.',
        code: 'not_authenticated',
      );
    }

    if (!_allowedAssignmentStatuses.contains(status)) {
      return const AppFailure(
        'Stato pagamento non valido.',
        code: 'invalid_fee_assignment_status',
      );
    }

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final resolvedAmountPaid = _amountPaidForStatus(
        status: status,
        amountDue: amountDue,
        amountPaid: amountPaid,
      );

      await _client
          .from('fee_assignments')
          .update({
            'status': status,
            'paid_at': status == 'paid' || status == 'partial' ? now : null,
            'amount_paid': resolvedAmountPaid,
            'updated_by': user.id,
          })
          .eq('id', assignmentId);

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile aggiornare il pagamento.',
        code: 'fee_assignment_update_error',
      );
    }
  }

  Future<AppResult<void>> deleteFee({required String feeId}) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (feeId.isEmpty) {
      return const AppFailure('Quota non valida.', code: 'invalid_fee_id');
    }

    try {
      final now = DateTime.now().toUtc().toIso8601String();

      await _client
          .from('fee_assignments')
          .update({'deleted_at': now})
          .eq('fee_id', feeId);

      await _client.from('fees').update({'deleted_at': now}).eq('id', feeId);

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile eliminare la quota.',
        code: 'fee_delete_error',
      );
    }
  }

  double _amountPaidForStatus({
    required String status,
    required double amountDue,
    double? amountPaid,
  }) {
    switch (status) {
      case 'paid':
        return amountDue;
      case 'partial':
        return amountPaid ?? 0;
      case 'unpaid':
      case 'waived':
      case 'overdue':
      default:
        return 0;
    }
  }

  Future<void> _softDeleteCreatedFee(String? feeId) async {
    if (feeId == null || feeId.isEmpty) {
      return;
    }

    try {
      final now = DateTime.now().toUtc().toIso8601String();

      await _client
          .from('fee_assignments')
          .update({'deleted_at': now})
          .eq('fee_id', feeId);

      await _client.from('fees').update({'deleted_at': now}).eq('id', feeId);
    } catch (_) {
      // Best effort rollback.
    }
  }

  static const Set<String> _allowedAssignmentStatuses = {
    'unpaid',
    'paid',
    'partial',
    'waived',
    'overdue',
  };

  Future<Map<String, String>> _fetchTeamNames(
    List<Map<String, dynamic>> rows,
  ) async {
    final ids = rows
        .map((row) => row['team_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (ids.isEmpty) {
      return {};
    }

    final data = await _client
        .from('teams')
        .select('id, name')
        .inFilter('id', ids);

    final teamRows = List<Map<String, dynamic>>.from(data);

    return {
      for (final row in teamRows)
        (row['id'] ?? '').toString(): (row['name'] ?? '').toString(),
    };
  }

  Future<Map<String, _FeeCounter>> _fetchAssignmentCounters(
    List<String> feeIds,
  ) async {
    if (feeIds.isEmpty) {
      return {};
    }

    final data = await _client
        .from('fee_assignments')
        .select('fee_id, status')
        .inFilter('fee_id', feeIds)
        .isFilter('deleted_at', null);

    final rows = List<Map<String, dynamic>>.from(data);
    final counters = <String, _FeeCounter>{};

    for (final row in rows) {
      final feeId = (row['fee_id'] ?? '').toString();
      final status = (row['status'] ?? 'unpaid').toString();

      final current = counters[feeId] ?? const _FeeCounter();

      counters[feeId] = current.copyWithStatus(status);
    }

    return counters;
  }
}

class _FeeCounter {
  const _FeeCounter({this.total = 0, this.paid = 0, this.unpaid = 0});

  final int total;
  final int paid;
  final int unpaid;

  _FeeCounter copyWithStatus(String status) {
    return _FeeCounter(
      total: total + 1,
      paid: paid + (status == 'paid' || status == 'waived' ? 1 : 0),
      unpaid: unpaid + (status == 'unpaid' || status == 'overdue' ? 1 : 0),
    );
  }
}
