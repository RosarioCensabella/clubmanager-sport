import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/permissions/club_role.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/club_detail.dart';
import '../domain/club_management_data.dart';
import '../domain/club_membership_summary.dart';
import '../domain/create_club_request.dart';
import '../domain/update_club_request.dart';
import '../domain/user_operational_context.dart';

class ClubContextRepository {
  ClubContextRepository();

  static const String _activeClubIdKey = 'active_club_id';
  static const String _activeOperationalContextPrefix =
      'active_operational_context_id';

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

  Future<AppResult<List<UserOperationalContext>>>
  fetchMyOperationalContextsForClub({
    required ClubMembershipSummary membership,
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
        'Devi effettuare l’accesso per vedere i contesti disponibili.',
        code: 'not_authenticated',
      );
    }

    final contextsById = <String, UserOperationalContext>{};

    void addContext(UserOperationalContext context) {
      contextsById[context.id] = context;
    }

    addContext(UserOperationalContext.fromClubMembership(membership));

    try {
      final teamMembershipData = await _client
          .from('team_memberships')
          .select(
            'id, team_id, role, teams(id, club_id, name, category, season)',
          )
          .eq('user_id', user.id)
          .eq('status', 'active');

      final teamMembershipRows = List<Map<String, dynamic>>.from(
        teamMembershipData,
      );

      for (final row in teamMembershipRows) {
        final rawTeam = row['teams'];
        final teamMap = rawTeam is Map
            ? Map<String, dynamic>.from(rawTeam)
            : <String, dynamic>{};

        final clubId = (teamMap['club_id'] ?? '').toString();

        if (clubId != membership.clubId) {
          continue;
        }

        final teamId = (teamMap['id'] ?? row['team_id'] ?? '').toString();
        final teamName = (teamMap['name'] ?? '').toString();

        if (teamId.isEmpty || teamName.isEmpty) {
          continue;
        }

        final category = teamMap['category']?.toString();
        final season = teamMap['season']?.toString();
        final subtitle = [
          if (category != null && category.trim().isNotEmpty) category.trim(),
          if (season != null && season.trim().isNotEmpty) season.trim(),
        ].join(' · ');

        addContext(
          UserOperationalContext.team(
            clubId: membership.clubId,
            teamId: teamId,
            teamName: teamName,
            role: clubRoleFromDatabaseValue(row['role']?.toString()),
            subtitle: subtitle,
          ),
        );
      }
    } catch (_) {
      // Il contesto club resta disponibile anche se i contesti squadra non sono caricabili.
    }

    try {
      final athleteData = await _client
          .from('athlete_profiles')
          .select(
            'id, club_id, user_id, team_id, first_name, last_name, teams(id, name)',
          )
          .eq('club_id', membership.clubId)
          .eq('user_id', user.id)
          .isFilter('deleted_at', null)
          .order('last_name')
          .order('first_name');

      final athleteRows = List<Map<String, dynamic>>.from(athleteData);

      for (final row in athleteRows) {
        final athleteId = (row['id'] ?? '').toString();
        final firstName = (row['first_name'] ?? '').toString();
        final lastName = (row['last_name'] ?? '').toString();
        final athleteName = '$firstName $lastName'.trim();

        if (athleteId.isEmpty || athleteName.isEmpty) {
          continue;
        }

        final rawTeam = row['teams'];
        final teamMap = rawTeam is Map
            ? Map<String, dynamic>.from(rawTeam)
            : <String, dynamic>{};

        addContext(
          UserOperationalContext.athlete(
            clubId: membership.clubId,
            athleteId: athleteId,
            athleteName: athleteName,
            teamId: row['team_id']?.toString(),
            teamName: teamMap['name']?.toString(),
          ),
        );
      }
    } catch (_) {
      // Il contesto club resta disponibile anche se il profilo atleta non è caricabile.
    }

    try {
      final relationData = await _client
          .from('parent_athlete_relations')
          .select(
            'id, relation_type, athlete_profile_id, athlete_profiles(id, club_id, team_id, first_name, last_name, teams(id, name))',
          )
          .eq('parent_user_id', user.id)
          .eq('verified', true);

      final relationRows = List<Map<String, dynamic>>.from(relationData);

      for (final row in relationRows) {
        final rawAthlete = row['athlete_profiles'];
        final athleteMap = rawAthlete is Map
            ? Map<String, dynamic>.from(rawAthlete)
            : <String, dynamic>{};

        final clubId = (athleteMap['club_id'] ?? '').toString();

        if (clubId != membership.clubId) {
          continue;
        }

        final athleteId = (athleteMap['id'] ?? '').toString();
        final firstName = (athleteMap['first_name'] ?? '').toString();
        final lastName = (athleteMap['last_name'] ?? '').toString();
        final athleteName = '$firstName $lastName'.trim();

        if (athleteId.isEmpty || athleteName.isEmpty) {
          continue;
        }

        final rawTeam = athleteMap['teams'];
        final teamMap = rawTeam is Map
            ? Map<String, dynamic>.from(rawTeam)
            : <String, dynamic>{};

        addContext(
          UserOperationalContext.child(
            clubId: membership.clubId,
            athleteId: athleteId,
            athleteName: athleteName,
            teamId: athleteMap['team_id']?.toString(),
            teamName: teamMap['name']?.toString(),
            relationLabel: _relationLabel(row['relation_type']?.toString()),
          ),
        );
      }
    } catch (_) {
      // Il contesto club resta disponibile anche se i figli/tutelati non sono caricabili.
    }

    return AppSuccess(contextsById.values.toList(growable: false));
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

  Future<String?> getActiveOperationalContextId({
    required String clubId,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_activeOperationalContextKey(clubId));
  }

  Future<void> setActiveOperationalContextId({
    required String clubId,
    required String contextId,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _activeOperationalContextKey(clubId),
      contextId,
    );
  }

  static String _activeOperationalContextKey(String clubId) {
    return '${_activeOperationalContextPrefix}_$clubId';
  }

  static String? _nullableTrim(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  static String _relationLabel(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'mother':
        return 'Madre';
      case 'father':
        return 'Padre';
      case 'guardian':
        return 'Tutore';
      default:
        return 'Genitore/Tutore';
    }
  }
}
