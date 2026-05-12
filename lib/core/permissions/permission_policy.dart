import 'app_permission.dart';
import 'club_role.dart';

class PermissionPolicy {
  const PermissionPolicy._();

  static bool can(ClubRole role, AppPermission permission) {
    switch (role) {
      case ClubRole.owner:
        return _ownerPermissions.contains(permission);

      case ClubRole.admin:
        return _adminPermissions.contains(permission);

      case ClubRole.teamManager:
        return _teamManagerPermissions.contains(permission);

      case ClubRole.coach:
        return _coachPermissions.contains(permission);

      case ClubRole.parent:
        return _parentPermissions.contains(permission);

      case ClubRole.athlete:
        return _athletePermissions.contains(permission);

      case ClubRole.staff:
        return _staffPermissions.contains(permission);
    }
  }

  static List<AppPermission> allowedPermissionsFor(ClubRole role) {
    return AppPermission.values
        .where((permission) => can(role, permission))
        .toList(growable: false);
  }

  static const Set<AppPermission> _ownerPermissions = {
    AppPermission.createClub,
    AppPermission.updateClub,
    AppPermission.createTeam,
    AppPermission.updateTeam,
    AppPermission.inviteMembers,
    AppPermission.manageMembers,
    AppPermission.createEvent,
    AppPermission.updateEvent,
    AppPermission.deleteEvent,
    AppPermission.manageCallups,
    AppPermission.markAttendance,
    AppPermission.publishAnnouncement,
    AppPermission.moderateContent,
    AppPermission.manageDocuments,
    AppPermission.viewDocuments,
    AppPermission.viewFees,
    AppPermission.manageFees,
    AppPermission.manageNotifications,
    AppPermission.viewAuditLog,
    AppPermission.requestAccountDeletion,
  };

  static const Set<AppPermission> _adminPermissions = {
    AppPermission.updateClub,
    AppPermission.createTeam,
    AppPermission.updateTeam,
    AppPermission.inviteMembers,
    AppPermission.manageMembers,
    AppPermission.createEvent,
    AppPermission.updateEvent,
    AppPermission.deleteEvent,
    AppPermission.manageCallups,
    AppPermission.markAttendance,
    AppPermission.publishAnnouncement,
    AppPermission.moderateContent,
    AppPermission.manageDocuments,
    AppPermission.viewDocuments,
    AppPermission.viewFees,
    AppPermission.manageFees,
    AppPermission.manageNotifications,
    AppPermission.viewAuditLog,
    AppPermission.requestAccountDeletion,
  };

  static const Set<AppPermission> _teamManagerPermissions = {
    AppPermission.inviteMembers,
    AppPermission.manageMembers,
    AppPermission.updateTeam,
    AppPermission.createEvent,
    AppPermission.updateEvent,
    AppPermission.deleteEvent,
    AppPermission.manageCallups,
    AppPermission.markAttendance,
    AppPermission.publishAnnouncement,
    AppPermission.manageDocuments,
    AppPermission.viewDocuments,
    AppPermission.viewFees,
    AppPermission.manageFees,
    AppPermission.manageNotifications,
    AppPermission.requestAccountDeletion,
  };

  static const Set<AppPermission> _coachPermissions = {
    AppPermission.inviteMembers,
    AppPermission.createEvent,
    AppPermission.updateEvent,
    AppPermission.manageCallups,
    AppPermission.markAttendance,
    AppPermission.publishAnnouncement,
    AppPermission.viewDocuments,
    AppPermission.manageNotifications,
    AppPermission.requestAccountDeletion,
  };

  static const Set<AppPermission> _parentPermissions = {
    AppPermission.submitRsvp,
    AppPermission.viewDocuments,
    AppPermission.viewFees,
    AppPermission.manageNotifications,
    AppPermission.requestAccountDeletion,
  };

  static const Set<AppPermission> _athletePermissions = {
    AppPermission.submitRsvp,
    AppPermission.viewDocuments,
    AppPermission.viewFees,
    AppPermission.manageNotifications,
    AppPermission.requestAccountDeletion,
  };

  static const Set<AppPermission> _staffPermissions = {
    AppPermission.manageDocuments,
    AppPermission.viewDocuments,
    AppPermission.manageNotifications,
    AppPermission.requestAccountDeletion,
  };
}
