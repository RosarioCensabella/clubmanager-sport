enum AppPermission {
  createClub,
  updateClub,
  createTeam,
  updateTeam,
  inviteMembers,
  manageMembers,
  createEvent,
  updateEvent,
  deleteEvent,
  manageCallups,
  submitRsvp,
  markAttendance,
  publishAnnouncement,
  moderateContent,
  manageDocuments,
  viewDocuments,
  viewFees,
  manageFees,
  manageNotifications,
  viewAuditLog,
  requestAccountDeletion,
}

extension AppPermissionX on AppPermission {
  String get label {
    switch (this) {
      case AppPermission.createClub:
        return 'Creare club';
      case AppPermission.updateClub:
        return 'Modificare club';
      case AppPermission.createTeam:
        return 'Creare squadre';
      case AppPermission.updateTeam:
        return 'Modificare squadre';
      case AppPermission.inviteMembers:
        return 'Invitare membri';
      case AppPermission.manageMembers:
        return 'Gestire membri';
      case AppPermission.createEvent:
        return 'Creare eventi';
      case AppPermission.updateEvent:
        return 'Modificare eventi';
      case AppPermission.deleteEvent:
        return 'Eliminare eventi';
      case AppPermission.manageCallups:
        return 'Gestire convocazioni';
      case AppPermission.submitRsvp:
        return 'Confermare presenza';
      case AppPermission.markAttendance:
        return 'Segnare presenze';
      case AppPermission.publishAnnouncement:
        return 'Pubblicare comunicazioni';
      case AppPermission.moderateContent:
        return 'Moderare contenuti';
      case AppPermission.manageDocuments:
        return 'Gestire documenti';
      case AppPermission.viewDocuments:
        return 'Vedere documenti';
      case AppPermission.viewFees:
        return 'Vedere quote';
      case AppPermission.manageFees:
        return 'Gestire quote';
      case AppPermission.manageNotifications:
        return 'Gestire notifiche';
      case AppPermission.viewAuditLog:
        return 'Vedere audit log';
      case AppPermission.requestAccountDeletion:
        return 'Richiedere cancellazione account';
    }
  }
}
