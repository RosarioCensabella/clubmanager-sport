import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/attendance_summary.dart';

class AttendanceRepository {
  AttendanceRepository();

  SupabaseClient get _client => SupabaseService.client;

  Future<AppResult<List<AttendanceSummary>>> fetchAttendanceForEvent({
    required String eventId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (eventId.isEmpty) {
      return const AppFailure('Evento non valido.', code: 'invalid_event_id');
    }

    try {
      final data = await _client
          .from('attendance')
          .select(
            'id, event_id, athlete_profile_id, status, notes, recorded_by, recorded_at, marked_by, created_at',
          )
          .eq('event_id', eventId)
          .order('created_at');

      final rows = List<Map<String, dynamic>>.from(data);

      final attendance = rows
          .map(AttendanceSummary.fromMap)
          .toList(growable: false);

      return AppSuccess(attendance);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare le presenze.',
        code: 'attendance_load_error',
      );
    }
  }

  Future<AppResult<void>> updateAttendance({
    required String eventId,
    required String athleteProfileId,
    required String status,
    required String? notes,
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
        'Devi effettuare l’accesso per registrare le presenze.',
        code: 'not_authenticated',
      );
    }

    if (eventId.isEmpty || athleteProfileId.isEmpty) {
      return const AppFailure(
        'Evento o atleta non valido.',
        code: 'invalid_attendance_target',
      );
    }

    if (!_allowedStatuses.contains(status)) {
      return const AppFailure(
        'Stato presenza non valido.',
        code: 'invalid_attendance_status',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await _client.from('attendance').upsert({
        'event_id': eventId,
        'athlete_profile_id': athleteProfileId,
        'status': status,
        'notes': _nullableTrim(notes),

        // Colonne nuove per la fase 17.
        'recorded_by': user.id,
        'recorded_at': now,

        // Colonna già presente e obbligatoria nel database remoto.
        'marked_by': user.id,
      }, onConflict: 'event_id,athlete_profile_id');

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile aggiornare la presenza.',
        code: 'attendance_update_error',
      );
    }
  }

  static const Set<String> _allowedStatuses = {
    'unknown',
    'present',
    'absent',
    'late',
    'excused',
  };

  static String? _nullableTrim(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
