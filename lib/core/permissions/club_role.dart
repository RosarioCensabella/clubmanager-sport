enum ClubRole { owner, admin, teamManager, coach, athlete, parent, staff }

ClubRole clubRoleFromDatabaseValue(String? value) {
  switch (value) {
    case 'owner':
      return ClubRole.owner;
    case 'admin':
      return ClubRole.admin;
    case 'team_manager':
      return ClubRole.teamManager;
    case 'coach':
      return ClubRole.coach;
    case 'athlete':
      return ClubRole.athlete;
    case 'parent':
      return ClubRole.parent;
    case 'staff':
      return ClubRole.staff;
    default:
      return ClubRole.athlete;
  }
}

extension ClubRoleX on ClubRole {
  String get databaseValue {
    switch (this) {
      case ClubRole.owner:
        return 'owner';
      case ClubRole.admin:
        return 'admin';
      case ClubRole.teamManager:
        return 'team_manager';
      case ClubRole.coach:
        return 'coach';
      case ClubRole.athlete:
        return 'athlete';
      case ClubRole.parent:
        return 'parent';
      case ClubRole.staff:
        return 'staff';
    }
  }

  String get label {
    switch (this) {
      case ClubRole.owner:
        return 'Owner';
      case ClubRole.admin:
        return 'Admin club';
      case ClubRole.teamManager:
        return 'Manager squadra';
      case ClubRole.coach:
        return 'Allenatore';
      case ClubRole.athlete:
        return 'Atleta';
      case ClubRole.parent:
        return 'Genitore/Tutore';
      case ClubRole.staff:
        return 'Staff';
    }
  }

  bool get isClubAdmin {
    return this == ClubRole.owner || this == ClubRole.admin;
  }

  bool get isStaffRole {
    return this == ClubRole.owner ||
        this == ClubRole.admin ||
        this == ClubRole.teamManager ||
        this == ClubRole.coach ||
        this == ClubRole.staff;
  }
}
