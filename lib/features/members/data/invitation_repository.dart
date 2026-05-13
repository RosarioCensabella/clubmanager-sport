import 'dart:convert';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/create_invitation_request.dart';
import '../domain/invitation_acceptance.dart';
import '../domain/invitation_summary.dart';

class InvitationRepository {
  InvitationRepository();

  SupabaseClient get _client => SupabaseService.client;

  Future<AppResult<List<InvitationSummary>>> fetchInvitationsForClub({
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
          .from('invitations')
          .select(
            'id, club_id, team_id, email, role, token, status, expires_at, created_at, teams(id, name)',
          )
          .eq('club_id', clubId)
          .order('created_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(data);

      final invitations = rows
          .map(InvitationSummary.fromMap)
          .toList(growable: false);

      return AppSuccess(invitations);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare gli inviti.',
        code: 'invitations_load_error',
      );
    }
  }

  Future<AppResult<InvitationAcceptance>> fetchInvitationByToken({
    required String token,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (token.trim().isEmpty) {
      return const AppFailure(
        'Token invito non valido.',
        code: 'invalid_invitation_token',
      );
    }

    try {
      final data = await _client.rpc(
        'get_invitation_by_token',
        params: {'invitation_token': token.trim()},
      );

      final rows = List<Map<String, dynamic>>.from(data);

      if (rows.isEmpty) {
        return const AppFailure(
          'Invito non trovato o non più disponibile.',
          code: 'invitation_not_found',
        );
      }

      return AppSuccess(InvitationAcceptance.fromMap(rows.first));
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile verificare l’invito.',
        code: 'invitation_lookup_error',
      );
    }
  }

  Future<AppResult<void>> acceptInvitation({required String token}) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (token.trim().isEmpty) {
      return const AppFailure(
        'Token invito non valido.',
        code: 'invalid_invitation_token',
      );
    }

    try {
      await _client.rpc(
        'accept_invitation',
        params: {'invitation_token': token.trim()},
      );

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile accettare l’invito.',
        code: 'invitation_accept_error',
      );
    }
  }

  Future<AppResult<String>> createInvitation(
    CreateInvitationRequest request,
  ) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    final user = _client.auth.currentUser;

    if (user == null) {
      return const AppFailure(
        'Devi effettuare l’accesso per creare un invito.',
        code: 'not_authenticated',
      );
    }

    try {
      final data = await _client
          .from('invitations')
          .insert(request.toInsertMap(invitedBy: user.id))
          .select('id')
          .single();

      final invitationId = (data['id'] ?? '').toString();

      if (invitationId.isEmpty) {
        return const AppFailure(
          'Invito creato, ma identificativo non ricevuto.',
          code: 'invitation_created_without_id',
        );
      }

      return AppSuccess(invitationId);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile creare l’invito. Riprova tra poco.',
        code: 'invitation_create_error',
      );
    }
  }

  Future<AppResult<void>> revokeInvitation({
    required String invitationId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (invitationId.isEmpty) {
      return const AppFailure(
        'Invito non valido.',
        code: 'invalid_invitation_id',
      );
    }

    try {
      await _client
          .from('invitations')
          .update({
            'status': 'revoked',
            'revoked_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', invitationId);

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile revocare l’invito.',
        code: 'invitation_revoke_error',
      );
    }
  }

  String generateInvitationToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));

    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
