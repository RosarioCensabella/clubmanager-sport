import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/permissions/club_role.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../../teams/domain/team_summary.dart';
import '../../teams/presentation/team_providers.dart';
import '../domain/member_summary.dart';
import 'member_providers.dart';

class AssignTeamMemberScreen extends ConsumerStatefulWidget {
  const AssignTeamMemberScreen({super.key});

  @override
  ConsumerState<AssignTeamMemberScreen> createState() =>
      _AssignTeamMemberScreenState();
}

class _AssignTeamMemberScreenState
    extends ConsumerState<AssignTeamMemberScreen> {
  late Future<AppResult<_AssignTeamMemberData>> _future;

  String? _activeClubId;
  String? _selectedUserId;
  String? _selectedTeamId;
  ClubRole _teamRole = ClubRole.teamManager;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<AppResult<_AssignTeamMemberData>> _loadData() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final memberRepository = ref.read(memberRepositoryProvider);
    final teamRepository = ref.read(teamRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return const AppFailure(
        'Seleziona un club prima di assegnare persone alle squadre.',
        code: 'active_club_missing',
      );
    }

    final membersResult = await memberRepository.fetchMembersForClub(
      clubId: _activeClubId!,
    );

    final teamsResult = await teamRepository.fetchTeamsForClub(
      clubId: _activeClubId!,
    );

    switch (membersResult) {
      case AppFailure(:final message, :final code):
        return AppFailure(message, code: code);

      case AppSuccess(:final data):
        final members = data;

        switch (teamsResult) {
          case AppFailure(:final message, :final code):
            return AppFailure(message, code: code);

          case AppSuccess(:final data):
            return AppSuccess(
              _AssignTeamMemberData(members: members, teams: data),
            );
        }
    }
  }

  Future<void> _submit() async {
    if (_isLoading) {
      return;
    }

    final clubId = _activeClubId;

    if (clubId == null || clubId.isEmpty) {
      return;
    }

    if (_selectedUserId == null || _selectedUserId!.isEmpty) {
      _showMessage('Seleziona una persona.');
      return;
    }

    if (_selectedTeamId == null || _selectedTeamId!.isEmpty) {
      _showMessage('Seleziona una squadra.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ref
        .read(memberRepositoryProvider)
        .assignUserToTeam(
          clubId: clubId,
          userId: _selectedUserId!,
          teamId: _selectedTeamId!,
          teamRole: _teamRole,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assegnazione squadra aggiornata.')),
        );
        context.pop(true);

      case AppFailure(:final message):
        _showMessage(message);
    }
  }

  Future<void> _pickMember(List<MemberSummary> members) async {
    final selected = await _showMemberPicker(
      title: 'Seleziona persona',
      members: members,
      selectedUserId: _selectedUserId,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedUserId = selected.userId;
    });
  }

  Future<void> _pickTeam(List<TeamSummary> teams) async {
    final selected = await _showTeamPicker(
      title: 'Seleziona squadra',
      teams: teams,
      selectedTeamId: _selectedTeamId,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedTeamId = selected.id;
    });
  }

  Future<void> _pickTeamRole() async {
    final selected = await showModalBottomSheet<ClubRole>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        const roles = [ClubRole.teamManager, ClubRole.coach, ClubRole.staff];

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                'Ruolo nella squadra',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              for (final role in roles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE0E6ED)),
                    ),
                    leading: const Icon(Icons.badge_outlined),
                    title: Text(_teamRoleLabel(role)),
                    trailing: role == _teamRole
                        ? const Icon(Icons.check_circle)
                        : const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pop(role),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _teamRole = selected;
    });
  }

  Future<MemberSummary?> _showMemberPicker({
    required String title,
    required List<MemberSummary> members,
    required String? selectedUserId,
  }) async {
    final searchController = TextEditingController();
    var query = '';

    final selected = await showModalBottomSheet<MemberSummary>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = members
                .where((member) {
                  final normalizedQuery = query.trim().toLowerCase();

                  if (normalizedQuery.isEmpty) {
                    return true;
                  }

                  return member.searchableText.contains(normalizedQuery);
                })
                .toList(growable: false);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Cerca',
                          hintText: 'Nome, email, ruolo...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            query = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('Nessun risultato.'))
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final member = filtered[index];

                                  return ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(
                                        color: Color(0xFFE0E6ED),
                                      ),
                                    ),
                                    leading: CircleAvatar(
                                      child: Text(member.initials),
                                    ),
                                    title: Text(member.fullName),
                                    subtitle: Text(
                                      [
                                        if (member.email.isNotEmpty)
                                          member.email,
                                        member.roleLabel,
                                      ].join(' · '),
                                    ),
                                    trailing: member.userId == selectedUserId
                                        ? const Icon(Icons.check_circle)
                                        : const Icon(Icons.chevron_right),
                                    onTap: () =>
                                        Navigator.of(context).pop(member),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    return selected;
  }

  Future<TeamSummary?> _showTeamPicker({
    required String title,
    required List<TeamSummary> teams,
    required String? selectedTeamId,
  }) async {
    final searchController = TextEditingController();
    var query = '';

    final selected = await showModalBottomSheet<TeamSummary>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = teams
                .where((team) {
                  final normalizedQuery = query.trim().toLowerCase();

                  if (normalizedQuery.isEmpty) {
                    return true;
                  }

                  return team.name.toLowerCase().contains(normalizedQuery);
                })
                .toList(growable: false);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Cerca squadra',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            query = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('Nessun risultato.'))
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final team = filtered[index];

                                  return ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(
                                        color: Color(0xFFE0E6ED),
                                      ),
                                    ),
                                    leading: const Icon(
                                      Icons.groups_2_outlined,
                                    ),
                                    title: Text(team.name),
                                    trailing: team.id == selectedTeamId
                                        ? const Icon(Icons.check_circle)
                                        : const Icon(Icons.chevron_right),
                                    onTap: () =>
                                        Navigator.of(context).pop(team),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    return selected;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  MemberSummary? _selectedMemberFrom(List<MemberSummary> members) {
    for (final member in members) {
      if (member.userId == _selectedUserId) {
        return member;
      }
    }

    return null;
  }

  TeamSummary? _selectedTeamFrom(List<TeamSummary> teams) {
    for (final team in teams) {
      if (team.id == _selectedTeamId) {
        return team;
      }
    }

    return null;
  }

  String _teamRoleLabel(ClubRole role) {
    switch (role) {
      case ClubRole.teamManager:
        return 'Manager squadra';
      case ClubRole.coach:
        return 'Allenatore';
      case ClubRole.staff:
        return 'Staff';
      default:
        return role.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assegna a squadra')),
      body: FutureBuilder<AppResult<_AssignTeamMemberData>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(message: 'Caricamento dati...');
          }

          final result = snapshot.data;

          if (result == null) {
            return AppErrorView(
              message: 'Risposta non valida durante il caricamento.',
              onRetry: () {
                setState(() {
                  _future = _loadData();
                });
              },
            );
          }

          switch (result) {
            case AppFailure(:final message):
              return AppErrorView(
                message: message,
                onRetry: () {
                  setState(() {
                    _future = _loadData();
                  });
                },
              );

            case AppSuccess(:final data):
              final assignableMembers = data.members
                  .where(
                    (member) =>
                        member.hasUserAccount && !member.isAthleteProfileOnly,
                  )
                  .toList(growable: false);

              final selectedMember = _selectedMemberFrom(assignableMembers);
              final selectedTeam = _selectedTeamFrom(data.teams);

              return SafeArea(
                minimum: const EdgeInsets.all(24),
                child: ListView(
                  children: [
                    Text(
                      'Assegna persona a squadra',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cerca una persona e assegnala a una squadra come manager, allenatore o staff.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF52616B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SelectorField(
                      label: 'Persona',
                      value: selectedMember == null
                          ? 'Seleziona persona'
                          : [
                              selectedMember.fullName,
                              selectedMember.roleLabel,
                            ].join(' · '),
                      icon: Icons.person_outline,
                      enabled: !_isLoading,
                      onTap: () => _pickMember(assignableMembers),
                    ),
                    const SizedBox(height: 16),
                    _SelectorField(
                      label: 'Squadra',
                      value: selectedTeam?.name ?? 'Seleziona squadra',
                      icon: Icons.groups_2_outlined,
                      enabled: !_isLoading,
                      onTap: () => _pickTeam(data.teams),
                    ),
                    const SizedBox(height: 16),
                    _SelectorField(
                      label: 'Ruolo nella squadra',
                      value: _teamRoleLabel(_teamRole),
                      icon: Icons.badge_outlined,
                      enabled: !_isLoading,
                      onTap: _pickTeamRole,
                    ),
                    const SizedBox(height: 28),
                    AppPrimaryButton(
                      label: 'Salva assegnazione',
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}

class _SelectorField extends StatelessWidget {
  const _SelectorField({
    required this.label,
    required this.value,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _AssignTeamMemberData {
  const _AssignTeamMemberData({required this.members, required this.teams});

  final List<MemberSummary> members;
  final List<TeamSummary> teams;
}
