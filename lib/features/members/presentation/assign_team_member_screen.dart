import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  String _memberQuery = '';
  String _teamQuery = '';
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

  void _reload() {
    setState(() {
      _future = _loadData();
    });
  }

  Future<void> _submit() async {
    if (_isLoading) {
      return;
    }

    final clubId = _activeClubId;

    if (clubId == null || clubId.isEmpty) {
      _showMessage('Club attivo non valido.');
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

    switch (result) {
      case AppSuccess():
        Navigator.of(context).pop(true);

      case AppFailure(:final message):
        setState(() {
          _isLoading = false;
        });

        _showMessage(message);
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<MemberSummary> _assignableMembers(List<MemberSummary> members) {
    final normalizedQuery = _memberQuery.trim().toLowerCase();

    return members
        .where((member) => member.userId.trim().isNotEmpty)
        .where((member) {
          if (normalizedQuery.isEmpty) {
            return true;
          }

          return member.searchableText.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  List<TeamSummary> _filteredTeams(List<TeamSummary> teams) {
    final normalizedQuery = _teamQuery.trim().toLowerCase();

    return teams
        .where((team) {
          if (normalizedQuery.isEmpty) {
            return true;
          }

          return team.name.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
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
              onRetry: _reload,
            );
          }

          switch (result) {
            case AppFailure(:final message):
              return AppErrorView(message: message, onRetry: _reload);

            case AppSuccess(:final data):
              final visibleMembers = _assignableMembers(data.members);
              final visibleTeams = _filteredTeams(data.teams);
              final selectedMember = _selectedMemberFrom(data.members);
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
                      'Cerca una persona, scegli la squadra e assegna il ruolo operativo.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF52616B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (selectedMember != null)
                      _SelectedValueCard(
                        icon: Icons.person_outline,
                        title: 'Persona selezionata',
                        value:
                            '${selectedMember.fullName} Â· ${selectedMember.roleLabel}',
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Cerca persona',
                        hintText: 'Nome, email, ruolo...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _memberQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const _SectionTitle(title: 'Persone disponibili'),
                    const SizedBox(height: 8),
                    if (visibleMembers.isEmpty)
                      const _EmptyInlineMessage(
                        message: 'Nessuna persona trovata.',
                      )
                    else
                      for (final member in visibleMembers) ...[
                        _SelectableMemberTile(
                          member: member,
                          selected: member.userId == _selectedUserId,
                          enabled: !_isLoading,
                          onTap: () {
                            setState(() {
                              _selectedUserId = member.userId;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 16),
                    if (selectedTeam != null)
                      _SelectedValueCard(
                        icon: Icons.groups_2_outlined,
                        title: 'Squadra selezionata',
                        value: selectedTeam.name,
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Cerca squadra',
                        hintText: 'Nome squadra...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _teamQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const _SectionTitle(title: 'Squadre disponibili'),
                    const SizedBox(height: 8),
                    if (visibleTeams.isEmpty)
                      const _EmptyInlineMessage(
                        message: 'Nessuna squadra trovata.',
                      )
                    else
                      for (final team in visibleTeams) ...[
                        _SelectableTeamTile(
                          team: team,
                          selected: team.id == _selectedTeamId,
                          enabled: !_isLoading,
                          onTap: () {
                            setState(() {
                              _selectedTeamId = team.id;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 16),
                    const _SectionTitle(title: 'Ruolo nella squadra'),
                    const SizedBox(height: 8),
                    _TeamRolePicker(
                      selectedRole: _teamRole,
                      enabled: !_isLoading,
                      onChanged: (role) {
                        setState(() {
                          _teamRole = role;
                        });
                      },
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

class _AssignTeamMemberData {
  const _AssignTeamMemberData({required this.members, required this.teams});

  final List<MemberSummary> members;
  final List<TeamSummary> teams;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _SelectedValueCard extends StatelessWidget {
  const _SelectedValueCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableMemberTile extends StatelessWidget {
  const _SelectableMemberTile({
    required this.member,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final MemberSummary member;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableTile(
      selected: selected,
      enabled: enabled,
      icon: Icons.person_outline,
      title: member.fullName,
      subtitle: member.email.isEmpty
          ? member.roleLabel
          : '${member.email} Â· ${member.roleLabel}',
      onTap: onTap,
    );
  }
}

class _SelectableTeamTile extends StatelessWidget {
  const _SelectableTeamTile({
    required this.team,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final TeamSummary team;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableTile(
      selected: selected,
      enabled: enabled,
      icon: Icons.groups_2_outlined,
      title: team.name,
      subtitle: 'Squadra',
      onTap: onTap,
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFFE0E6ED),
          width: selected ? 2 : 1,
        ),
      ),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected
          ? const Icon(Icons.check_circle)
          : const Icon(Icons.chevron_right),
      onTap: enabled ? onTap : null,
    );
  }
}

class _TeamRolePicker extends StatelessWidget {
  const _TeamRolePicker({
    required this.selectedRole,
    required this.enabled,
    required this.onChanged,
  });

  final ClubRole selectedRole;
  final bool enabled;
  final ValueChanged<ClubRole> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      _TeamRoleOption(role: ClubRole.owner, label: 'Proprietario'),
      _TeamRoleOption(role: ClubRole.admin, label: 'Amministratore'),
      _TeamRoleOption(
        role: ClubRole.teamManager,
        label: 'Responsabile squadra',
      ),
      _TeamRoleOption(role: ClubRole.coach, label: 'Allenatore'),
      _TeamRoleOption(role: ClubRole.staff, label: 'Staff'),
      _TeamRoleOption(role: ClubRole.athlete, label: 'Atleta'),
      _TeamRoleOption(role: ClubRole.parent, label: 'Genitore/Tutore'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(option.label),
            selected: selectedRole == option.role,
            onSelected: enabled ? (_) => onChanged(option.role) : null,
          ),
      ],
    );
  }
}

class _TeamRoleOption {
  const _TeamRoleOption({required this.role, required this.label});

  final ClubRole role;
  final String label;
}

class _EmptyInlineMessage extends StatelessWidget {
  const _EmptyInlineMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF52616B)),
        ),
      ),
    );
  }
}
