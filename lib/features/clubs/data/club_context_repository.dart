import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/club_membership_summary.dart';

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
            'id, club_id, user_id, role, status, clubs(id, name, sport_primary, city, logo_url, primary_color)',
          )
          .eq('user_id', user.id)
          .eq('status', 'active')
          .order('created_at');

      final rows = List<Map<String, dynamic>>.from(data);

      final memberships = rows
          .map(ClubMembershipSummary.fromMap)
          .where((membership) => membership.club.id.isNotEmpty)
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
}
