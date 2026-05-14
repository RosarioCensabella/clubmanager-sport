import '../../../core/permissions/club_role.dart';
import 'club_membership_summary.dart';

enum ClubDashboardKind { clubAdmin, staff, user, unknown }

class ClubDashboardProfile {
  const ClubDashboardProfile({
    required this.kind,
    required this.title,
    required this.description,
    required this.primaryActionLabel,
    required this.isManagementDashboard,
    required this.canManageClub,
    required this.canManageTeams,
    required this.canManageAthletes,
    required this.canManageInvitations,
    required this.canManageEvents,
    required this.canManageCommunications,
    required this.canManageDocuments,
    required this.canManageFees,
  });

  final ClubDashboardKind kind;
  final String title;
  final String description;
  final String primaryActionLabel;
  final bool isManagementDashboard;
  final bool canManageClub;
  final bool canManageTeams;
  final bool canManageAthletes;
  final bool canManageInvitations;
  final bool canManageEvents;
  final bool canManageCommunications;
  final bool canManageDocuments;
  final bool canManageFees;

  factory ClubDashboardProfile.fromMembership(
    ClubMembershipSummary membership,
  ) {
    final role = membership.role;

    if (role == ClubRole.owner || role == ClubRole.admin) {
      return const ClubDashboardProfile(
        kind: ClubDashboardKind.clubAdmin,
        title: 'Dashboard gestionale',
        description:
            'Gestisci il club, le squadre, gli atleti, gli inviti, gli eventi e le attività operative.',
        primaryActionLabel: 'Gestione completa club',
        isManagementDashboard: true,
        canManageClub: true,
        canManageTeams: true,
        canManageAthletes: true,
        canManageInvitations: true,
        canManageEvents: true,
        canManageCommunications: true,
        canManageDocuments: true,
        canManageFees: true,
      );
    }

    if (role == ClubRole.teamManager) {
      return const ClubDashboardProfile(
        kind: ClubDashboardKind.staff,
        title: 'Dashboard responsabile squadra',
        description:
            'Gestisci attività operative, squadre, atleti, eventi e comunicazioni in base ai permessi assegnati.',
        primaryActionLabel: 'Gestione operativa',
        isManagementDashboard: true,
        canManageClub: false,
        canManageTeams: true,
        canManageAthletes: true,
        canManageInvitations: false,
        canManageEvents: true,
        canManageCommunications: true,
        canManageDocuments: true,
        canManageFees: false,
      );
    }

    if (role == ClubRole.coach) {
      return const ClubDashboardProfile(
        kind: ClubDashboardKind.staff,
        title: 'Dashboard allenatore',
        description:
            'Gestisci eventi, convocazioni, presenze e comunicazioni per le squadre assegnate.',
        primaryActionLabel: 'Gestione squadra',
        isManagementDashboard: true,
        canManageClub: false,
        canManageTeams: true,
        canManageAthletes: true,
        canManageInvitations: false,
        canManageEvents: true,
        canManageCommunications: true,
        canManageDocuments: false,
        canManageFees: false,
      );
    }

    if (role == ClubRole.staff) {
      return const ClubDashboardProfile(
        kind: ClubDashboardKind.staff,
        title: 'Dashboard staff',
        description:
            'Accedi alle aree operative abilitate dal club. I permessi saranno resi granulari nelle prossime fasi.',
        primaryActionLabel: 'Area staff',
        isManagementDashboard: true,
        canManageClub: false,
        canManageTeams: false,
        canManageAthletes: true,
        canManageInvitations: false,
        canManageEvents: true,
        canManageCommunications: true,
        canManageDocuments: true,
        canManageFees: false,
      );
    }

    if (role == ClubRole.parent) {
      return const ClubDashboardProfile(
        kind: ClubDashboardKind.user,
        title: 'Dashboard genitore/tutore',
        description:
            'Consulta eventi, convocazioni, documenti, quote e comunicazioni relative agli atleti collegati.',
        primaryActionLabel: 'Area famiglia',
        isManagementDashboard: false,
        canManageClub: false,
        canManageTeams: false,
        canManageAthletes: false,
        canManageInvitations: false,
        canManageEvents: true,
        canManageCommunications: true,
        canManageDocuments: true,
        canManageFees: true,
      );
    }

    if (role == ClubRole.athlete) {
      return const ClubDashboardProfile(
        kind: ClubDashboardKind.user,
        title: 'Dashboard atleta',
        description:
            'Consulta eventi, convocazioni, comunicazioni e documenti collegati al tuo profilo atleta.',
        primaryActionLabel: 'Area atleta',
        isManagementDashboard: false,
        canManageClub: false,
        canManageTeams: false,
        canManageAthletes: false,
        canManageInvitations: false,
        canManageEvents: true,
        canManageCommunications: true,
        canManageDocuments: true,
        canManageFees: false,
      );
    }

    return const ClubDashboardProfile(
      kind: ClubDashboardKind.unknown,
      title: 'Accesso limitato',
      description:
          'Il ruolo collegato al tuo account non è riconosciuto. Contatta l’amministratore del club.',
      primaryActionLabel: 'Accesso limitato',
      isManagementDashboard: false,
      canManageClub: false,
      canManageTeams: false,
      canManageAthletes: false,
      canManageInvitations: false,
      canManageEvents: false,
      canManageCommunications: false,
      canManageDocuments: false,
      canManageFees: false,
    );
  }
}
