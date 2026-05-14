import '../../../core/permissions/club_role.dart';
import 'club_membership_summary.dart';

enum UserOperationalContextType { club, team, athlete, child }

class UserOperationalContext {
  const UserOperationalContext({
    required this.id,
    required this.clubId,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.roleLabel,
    this.teamId,
    this.teamName,
    this.athleteId,
    this.athleteName,
  });

  final String id;
  final String clubId;
  final UserOperationalContextType type;
  final String title;
  final String subtitle;
  final String roleLabel;
  final String? teamId;
  final String? teamName;
  final String? athleteId;
  final String? athleteName;

  String get typeLabel {
    switch (type) {
      case UserOperationalContextType.club:
        return 'Club';
      case UserOperationalContextType.team:
        return 'Squadra';
      case UserOperationalContextType.athlete:
        return 'Atleta';
      case UserOperationalContextType.child:
        return 'Figlio/Tutelato';
    }
  }

  factory UserOperationalContext.fromClubMembership(
    ClubMembershipSummary membership,
  ) {
    return UserOperationalContext(
      id: 'club:${membership.clubId}',
      clubId: membership.clubId,
      type: UserOperationalContextType.club,
      title: membership.club.name,
      subtitle: '${membership.club.sportPrimary} · ${membership.club.city}',
      roleLabel: membership.role.label,
    );
  }

  factory UserOperationalContext.team({
    required String clubId,
    required String teamId,
    required String teamName,
    required ClubRole role,
    String? subtitle,
  }) {
    return UserOperationalContext(
      id: 'team:$teamId',
      clubId: clubId,
      type: UserOperationalContextType.team,
      title: teamName,
      subtitle: subtitle?.trim().isNotEmpty == true
          ? subtitle!.trim()
          : 'Squadra collegata',
      roleLabel: role.label,
      teamId: teamId,
      teamName: teamName,
    );
  }

  factory UserOperationalContext.athlete({
    required String clubId,
    required String athleteId,
    required String athleteName,
    String? teamId,
    String? teamName,
  }) {
    return UserOperationalContext(
      id: 'athlete:$athleteId',
      clubId: clubId,
      type: UserOperationalContextType.athlete,
      title: athleteName,
      subtitle: teamName?.trim().isNotEmpty == true
          ? 'Atleta · $teamName'
          : 'Atleta del club',
      roleLabel: 'Atleta',
      teamId: teamId,
      teamName: teamName,
      athleteId: athleteId,
      athleteName: athleteName,
    );
  }

  factory UserOperationalContext.child({
    required String clubId,
    required String athleteId,
    required String athleteName,
    String? teamId,
    String? teamName,
    String? relationLabel,
  }) {
    return UserOperationalContext(
      id: 'child:$athleteId',
      clubId: clubId,
      type: UserOperationalContextType.child,
      title: athleteName,
      subtitle: [
        relationLabel?.trim().isNotEmpty == true
            ? relationLabel!.trim()
            : 'Figlio/Tutelato',
        if (teamName?.trim().isNotEmpty == true) teamName!.trim(),
      ].join(' · '),
      roleLabel: 'Genitore/Tutore',
      teamId: teamId,
      teamName: teamName,
      athleteId: athleteId,
      athleteName: athleteName,
    );
  }
}
