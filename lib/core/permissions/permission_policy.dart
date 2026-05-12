import 'app_permission.dart';
import 'club_role.dart';

class PermissionPolicy {
  const PermissionPolicy._();

  static List<AppPermission> allowedPermissionsFor(ClubRole role) {
    switch (role) {
      case ClubRole.owner:
      case ClubRole.admin:
      case ClubRole.teamManager:
      case ClubRole.coach:
      case ClubRole.staff:
        return AppPermission.values;

      case ClubRole.athlete:
        return _permissionsMatchingAny([
          'view',
          'read',
          'own',
          'rsvp',
          'attendance',
          'event',
          'communication',
          'document',
          'profile',
        ]);

      case ClubRole.parent:
        return _permissionsMatchingAny([
          'view',
          'read',
          'own',
          'child',
          'athlete',
          'rsvp',
          'attendance',
          'event',
          'communication',
          'document',
          'fee',
          'profile',
        ]);

      case ClubRole.unknown:
        return const [];
    }
  }

  static bool can(ClubRole role, AppPermission permission) {
    return allowedPermissionsFor(role).contains(permission);
  }

  static List<AppPermission> _permissionsMatchingAny(List<String> keywords) {
    return AppPermission.values
        .where((permission) {
          final name = permission.name.toLowerCase();

          return keywords.any(name.contains);
        })
        .toList(growable: false);
  }
}
