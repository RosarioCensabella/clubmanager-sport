import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/create_invitation_request.dart';
import '../domain/invitation_acceptance.dart';
import '../domain/invitation_summary.dart';

class InvitationRepository {
  InvitationRepository();

  static const String _pendingInvitationTokenKey = 'pending_invitation_token';

  static const String _invitationBaseUrl = String.fromEnvironment(
    'INVITATION_BASE_URL',
    defaultValue: 'clubmanager-sport://app/invite',
  );

  SupabaseClient get _client => SupabaseService.client;

  String buildInvitationLink(String token) {
    final cleanBase = _invitationBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final encodedToken = Uri.encodeComponent(token.trim());

    if (cleanBase.endsWith('/invite')) {
      return '$cleanBase/$encodedToken';
    }

    return '$cleanBase/invite/$encodedToken';
  }

  Future<void> savePendingInvitationToken(String token) async {
    final cleanToken = token.trim();

    if (cleanToken.isEmpty) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_pendingInvitationTokenKey, cleanToken);
  }

  Future<String?> getPendingInvitationToken() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(_pendingInvitationTokenKey)?.trim();

    if (token == null || token.isEmpty) {
      return null;
    }

    return token;
  }

  Future<void> clearPendingInvitationToken() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_pendingInvitationTokenKey);
  }

  String extractInvitationToken(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(text);

    if (uri != null && uri.hasScheme) {
      final tokenFromQuery = uri.queryParameters['token'];

      if (tokenFromQuery != null && tokenFromQuery.trim().isNotEmpty) {
        return tokenFromQuery.trim();
      }

      final segments = uri.pathSegments;

      final inviteIndex = segments.indexWhere(
        (segment) => segment.toLowerCase() == 'invite',
      );

      if (inviteIndex >= 0 && inviteIndex + 1 < segments.length) {
        return Uri.decodeComponent(segments[inviteIndex + 1]).trim();
      }

      if (uri.host.toLowerCase() == 'invite' && segments.isNotEmpty) {
        return Uri.decodeComponent(segments.first).trim();
      }
    }

    return text;
  }

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
            'id, club_id, team_id, email, role, token, status, expires_at, created_at, email_sent_at, email_last_error, email_send_attempts, teams(id, name)',
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
      return AppFailure(_mapInvitationError(error.message), code: error.code);
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

      await clearPendingInvitationToken();

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(_mapInvitationError(error.message), code: error.code);
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

  Future<AppResult<void>> sendInvitationEmail({
    required String invitationId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (invitationId.trim().isEmpty) {
      return const AppFailure(
        'Invito non valido.',
        code: 'invalid_invitation_id',
      );
    }

    try {
      final response = await _client.functions.invoke(
        'send-invitation-email',
        body: {'invitation_id': invitationId.trim()},
      );

      final data = response.data;

      if (data is Map && data['ok'] == false) {
        final message = (data['message'] ?? 'Invio email non riuscito.')
            .toString();

        return AppFailure(message, code: 'invitation_email_send_failed');
      }

      return const AppSuccess(null);
    } on FunctionException catch (error) {
      return AppFailure(
        _mapFunctionEmailError(error),
        code: 'invitation_email_send_error',
      );
    } catch (_) {
      return const AppFailure(
        'Invio email non riuscito. Controlla configurazione provider email e riprova.',
        code: 'invitation_email_send_error',
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

  Future<AppResult<void>> deleteInvitation({
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
          .delete()
          .eq('id', invitationId)
          .eq('status', 'revoked');

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile cancellare l’invito.',
        code: 'invitation_delete_error',
      );
    }
  }

  String generateInvitationToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));

    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _mapInvitationError(String message) {
    final normalized = message.toLowerCase();

    if (normalized.contains('not_authenticated')) {
      return 'Devi effettuare l’accesso prima di accettare l’invito.';
    }

    if (normalized.contains('invalid_invitation_email')) {
      return 'Questo invito è associato a un’altra email. Accedi con l’email invitata.';
    }

    if (normalized.contains('invitation_not_found')) {
      return 'Invito non trovato.';
    }

    if (normalized.contains('invitation_expired')) {
      return 'Questo invito è scaduto. Chiedi al club di inviartene uno nuovo.';
    }

    if (normalized.contains('invitation_already_accepted')) {
      return 'Questo invito è già stato accettato.';
    }

    if (normalized.contains('invitation_not_available')) {
      return 'Questo invito non è più disponibile.';
    }

    if (normalized.contains('athlete_profile_already_linked')) {
      return 'Questo atleta è già collegato a un altro account.';
    }

    return message;
  }

  String _mapFunctionEmailError(FunctionException error) {
    final details = error.details.toString();

    if (details.contains('You can only send testing emails')) {
      return 'Resend è in modalità test: puoi inviare email solo all’indirizzo del tuo account Resend. Per inviare ad altri destinatari devi verificare un dominio su Resend.';
    }

    if (details.contains('domain is not verified')) {
      return 'Il dominio del mittente non è verificato su Resend. Usa onboarding@resend.dev per test o verifica un dominio tuo.';
    }

    if (details.contains('RESEND_API_KEY')) {
      return 'Provider email non configurato. Imposta RESEND_API_KEY nei secrets Supabase.';
    }

    return 'Invio email non riuscito. Controlla provider email e configurazione Supabase.';
  }
}
