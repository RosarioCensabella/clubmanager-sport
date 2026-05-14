import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/club_detail.dart';
import '../domain/club_management_data.dart';
import '../domain/club_membership_summary.dart';
import '../domain/create_club_request.dart';
import '../domain/update_club_request.dart';

class ClubContextRepository {
  ClubContextRepository();

  static const String _activeClubIdKey = 'active_club_id';

  SupabaseClient get _client => SupabaseService.client;

  Future<AppResult<List<ClubMembershipSummary>>>
  fetchMyClubMemberships() async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    final user = _client.auth.currentUser;

    if (user == null) {
      return const AppFailure(
        'Devi effettuare l’accesso per vedere i tuoi club.',
        code: 'not_authenticated',
      );
    }

    try {
      final data = await _client
          .from('club_memberships')
          .select(
            'id, club_id, user_id, role, status, clubs(id, name, sport_primary, city, logo_url, primary_color, deleted_at)',
          )
          .eq('user_id', user.id)
          .eq('status', 'active')
          .order('created_at');

      final rows = List<Map<String, dynamic>>.from(data);

      final memberships = rows
          .map(ClubMembershipSummary.fromMap)
          .where((membership) => membership.club.id.isNotEmpty)
          .where((membership) => !membership.club.isArchived)
          .toList(growable: false);

      return AppSuccess(memberships);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare i club collegati al tuo account.',
        code: 'club_context_load_error',
      );
    }
  }

  Future<AppResult<ClubDetail>> fetchClubById({required String clubId}) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (clubId.trim().isEmpty) {
      return const AppFailure('Club non valido.', code: 'invalid_club_id');
    }

    try {
      final data = await _client
          .from('clubs')
          .select(
            'id, owner_user_id, name, logo_url, sport_primary, city, address, email, phone, website, fiscal_code, season, subscription_plan, subscription_status, primary_color, created_at, updated_at, deleted_at, archived_at, archived_by, archive_reason',
          )
          .eq('id', clubId)
          .maybeSingle();

      if (data == null) {
        return const AppFailure(
          'Club non trovato o non disponibile.',
          code: 'club_not_found',
        );
      }

      return AppSuccess(ClubDetail.fromMap(Map<String, dynamic>.from(data)));
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare i dettagli del club.',
        code: 'club_detail_load_error',
      );
    }
  }

  Future<AppResult<ClubManagementData>> fetchClubManagementData({
    required String clubId,
  }) async {
    final membershipsResult = await fetchMyClubMemberships();

    switch (membershipsResult) {
      case AppFailure(:final message, :final code):
        return AppFailure(message, code: code);

      case AppSuccess(:final data):
        final matches = data.where((membership) => membership.clubId == clubId);

        if (matches.isEmpty) {
          return const AppFailure(
            'Non hai accesso a questo club.',
            code: 'club_membership_not_found',
          );
        }

        final clubResult = await fetchClubById(clubId: clubId);

        switch (clubResult) {
          case AppFailure(:final message, :final code):
            return AppFailure(message, code: code);

          case AppSuccess(:final data):
            return AppSuccess(
              ClubManagementData(club: data, membership: matches.first),
            );
        }
    }
  }

  Future<AppResult<String>> createClub(CreateClubRequest request) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    final user = _client.auth.currentUser;

    if (user == null) {
      return const AppFailure(
        'Devi effettuare l’accesso per creare un club.',
        code: 'not_authenticated',
      );
    }

    try {
      final data = await _client
          .from('clubs')
          .insert(request.toInsertMap(ownerUserId: user.id))
          .select('id')
          .single();

      final clubId = (data['id'] ?? '').toString();

      if (clubId.isEmpty) {
        return const AppFailure(
          'Club creato, ma identificativo non ricevuto.',
          code: 'club_created_without_id',
        );
      }

      await setActiveClubId(clubId);

      return AppSuccess(clubId);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile creare il club. Riprova tra poco.',
        code: 'club_create_error',
      );
    }
  }

  Future<AppResult<void>> updateClub({
    required String clubId,
    required UpdateClubRequest request,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (clubId.trim().isEmpty) {
      return const AppFailure('Club non valido.', code: 'invalid_club_id');
    }

    try {
      await _client
          .from('clubs')
          .update(request.toUpdateMap())
          .eq('id', clubId);

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile aggiornare il club.',
        code: 'club_update_error',
      );
    }
  }

  Future<AppResult<void>> archiveClub({
    required String clubId,
    String? reason,
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
        'Devi effettuare l’accesso per archiviare il club.',
        code: 'not_authenticated',
      );
    }

    if (clubId.trim().isEmpty) {
      return const AppFailure('Club non valido.', code: 'invalid_club_id');
    }

    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await _client
          .from('clubs')
          .update({
            'deleted_at': now,
            'archived_at': now,
            'archived_by': user.id,
            'archive_reason': _nullableTrim(reason),
          })
          .eq('id', clubId);

      final activeClubId = await getActiveClubId();

      if (activeClubId == clubId) {
        await clearActiveClubId();
      }

      return const AppSuccess(null);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile archiviare il club.',
        code: 'club_archive_error',
      );
    }
  }

  Future<String?> getActiveClubId() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_activeClubIdKey);
  }

  Future<void> setActiveClubId(String clubId) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_activeClubIdKey, clubId);
  }

  Future<void> clearActiveClubId() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_activeClubIdKey);
  }

  static String? _nullableTrim(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
