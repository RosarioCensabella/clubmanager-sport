import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/permissions/club_role.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';

class MemberAdminRepository {
  MemberAdminRepository();

  SupabaseClient get _client => SupabaseService.client;

  Future<AppResult<void>> updateMember({
    required String clubId,
    required String userId,
    required String firstName,
    required String lastName,
    required ClubRole role,
    required String status,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (clubId.trim().isEmpty || userId.trim().isEmpty) {
      return const AppFailure(
        'Dati persona incompleti.',
        code: 'invalid_member_update',
      );
    }

    if (role == ClubRole.unknown) {
      return const AppFailure('Ruolo non valido.', code: 'invalid_member_role');
    }

    if (!_isValidStatus(status)) {
      return const AppFailure(
        'Stato accesso non valido.',
        code: 'invalid_member_status',
      );
    }

    try {
      await _client.rpc(
        'member_access_update_member',
        params: {
          'target_club_id': clubId.trim(),
          'target_user_id': userId.trim(),
          'target_first_name': firstName.trim(),
          'target_last_name': lastName.trim(),
          'target_role': role.databaseValue,
          'target_status': status.trim(),
        },
      );

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(_mapError(error), code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile aggiornare la persona.',
        code: 'member_update_error',
      );
    }
  }

  Future<AppResult<void>> removeTeamAssignment({
    required String assignmentId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (assignmentId.trim().isEmpty ||
        assignmentId.startsWith('athlete-team')) {
      return const AppFailure(
        'Assegnazione squadra non valida.',
        code: 'invalid_team_assignment',
      );
    }

    try {
      await _client.rpc(
        'member_access_remove_team_assignment',
        params: {'target_assignment_id': assignmentId.trim()},
      );

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(_mapError(error), code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile rimuovere l’assegnazione squadra.',
        code: 'team_assignment_remove_error',
      );
    }
  }

  Future<AppResult<void>> removeParentRelation({
    required String relationId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (relationId.trim().isEmpty) {
      return const AppFailure(
        'Collegamento genitore-atleta non valido.',
        code: 'invalid_parent_relation',
      );
    }

    try {
      await _client.rpc(
        'member_access_remove_parent_relation',
        params: {'target_relation_id': relationId.trim()},
      );

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(_mapError(error), code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile rimuovere il collegamento genitore-atleta.',
        code: 'parent_relation_remove_error',
      );
    }
  }

  Future<AppResult<void>> unlinkAthleteAccount({
    required String clubId,
    required String athleteId,
    required String userId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (clubId.trim().isEmpty ||
        athleteId.trim().isEmpty ||
        userId.trim().isEmpty) {
      return const AppFailure(
        'Dati collegamento atleta incompleti.',
        code: 'invalid_athlete_unlink',
      );
    }

    try {
      await _client.rpc(
        'member_access_unlink_athlete_account',
        params: {
          'target_club_id': clubId.trim(),
          'target_athlete_id': athleteId.trim(),
          'target_user_id': userId.trim(),
        },
      );

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(_mapError(error), code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile scollegare l’account atleta.',
        code: 'athlete_account_unlink_error',
      );
    }
  }

  bool _isValidStatus(String status) {
    return status == 'active' ||
        status == 'pending' ||
        status == 'suspended' ||
        status == 'removed';
  }

  String _mapError(PostgrestException error) {
    final message = error.message;

    if (message.contains('not_authenticated')) {
      return 'Devi effettuare l’accesso.';
    }

    if (message.contains('not_authorized')) {
      return 'Solo proprietario o amministratore può modificare persone e accessi.';
    }

    if (message.contains('member_not_found')) {
      return 'Persona non trovata nel club attivo.';
    }

    if (message.contains('cannot_change_owner_role')) {
      return 'Il proprietario del club non può essere declassato da questa schermata.';
    }

    if (message.contains('cannot_promote_owner')) {
      return 'Non puoi creare un secondo proprietario da questa schermata.';
    }

    if (message.contains('invalid_member_role')) {
      return 'Ruolo non valido.';
    }

    if (message.contains('invalid_member_status')) {
      return 'Stato accesso non valido.';
    }

    if (message.contains('team_assignment_not_found')) {
      return 'Assegnazione squadra non trovata.';
    }

    if (message.contains('parent_relation_not_found')) {
      return 'Collegamento genitore-atleta non trovato.';
    }

    if (message.contains('athlete_profile_not_found')) {
      return 'Scheda atleta non trovata.';
    }

    return 'Operazione non riuscita. Controlla i permessi e riprova.';
  }
}
