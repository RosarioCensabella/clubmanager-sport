enum ClubRole {
  owner('owner'),
  admin('admin'),
  teamManager('team_manager'),
  coach('coach'),
  staff('staff'),
  athlete('athlete'),
  parent('parent'),
  unknown('unknown');

  const ClubRole(this.databaseValue);

  final String databaseValue;

  String get label {
    switch (this) {
      case ClubRole.owner:
        return 'Proprietario';
      case ClubRole.admin:
        return 'Amministratore';
      case ClubRole.teamManager:
        return 'Responsabile squadra';
      case ClubRole.coach:
        return 'Allenatore';
      case ClubRole.staff:
        return 'Staff';
      case ClubRole.athlete:
        return 'Atleta';
      case ClubRole.parent:
        return 'Genitore/Tutore';
      case ClubRole.unknown:
        return 'Ruolo sconosciuto';
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

  bool get isFamilyRole {
    return this == ClubRole.parent || this == ClubRole.athlete;
  }

  static ClubRole fromDatabaseValue(String? value) {
    final normalized = value?.trim().toLowerCase();

    if (normalized == null || normalized.isEmpty) {
      return ClubRole.unknown;
    }

    for (final role in ClubRole.values) {
      if (role.databaseValue == normalized ||
          role.name.toLowerCase() == normalized) {
        return role;
      }
    }

    if (normalized == 'teammanager' || normalized == 'team-manager') {
      return ClubRole.teamManager;
    }

    return ClubRole.unknown;
  }
}

ClubRole clubRoleFromDatabaseValue(String? value) {
  return ClubRole.fromDatabaseValue(value);
}
