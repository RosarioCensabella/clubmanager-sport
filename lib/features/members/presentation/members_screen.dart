import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../domain/member_summary.dart';
import 'member_providers.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _searchController = TextEditingController();

  late Future<AppResult<List<MemberSummary>>> _future;

  String? _activeClubId;
  String _query = '';
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _future = _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<AppResult<List<MemberSummary>>> _loadMembers() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final memberRepository = ref.read(memberRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return const AppFailure(
        'Seleziona o crea un club prima di gestire persone e accessi.',
        code: 'active_club_missing',
      );
    }

    return memberRepository.fetchMembersForClub(clubId: _activeClubId!);
  }

  void _reload() {
    setState(() {
      _future = _loadMembers();
    });
  }

  void _goToInvitations() {
    context.push('/invitations').then((_) {
      if (!mounted) {
        return;
      }

      _reload();
    });
  }

  void _goToCreateInvitation() {
    context.push('/invitations/create').then((_) {
      if (!mounted) {
        return;
      }

      _reload();
    });
  }

  void _goToAssignTeam() {
    context.push('/members/assign-team').then((result) {
      if (!mounted) {
        return;
      }

      _reload();

      if (result == true) {
        _showMessage('Assegnazione squadra aggiornata.');
      }
    });
  }

  void _goToLinkParent() {
    context.push('/members/link-parent').then((result) {
      if (!mounted) {
        return;
      }

      _reload();

      if (result == true) {
        _showMessage('Genitore/tutore collegato.');
      }
    });
  }

  void _goToLinkAthleteAccount() {
    context.push('/members/link-athlete-account').then((result) {
      if (!mounted) {
        return;
      }

      _reload();

      if (result == true) {
        _showMessage('Account atleta collegato.');
      }
    });
  }

  void _showMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });
  }

  List<MemberSummary> _applyFilters(List<MemberSummary> members) {
    final normalizedQuery = _query.trim().toLowerCase();

    return members
        .where((member) {
          final roleMatches =
              _roleFilter == 'all' || member.role.databaseValue == _roleFilter;

          final queryMatches =
              normalizedQuery.isEmpty ||
              member.searchableText.contains(normalizedQuery);

          return roleMatches && queryMatches;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persone e accessi'),
        actions: [
          IconButton(
            tooltip: 'Inviti',
            onPressed: _goToInvitations,
            icon: const Icon(Icons.mark_email_read_outlined),
          ),
          IconButton(
            tooltip: 'Nuovo invito',
            onPressed: _goToCreateInvitation,
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      body: FutureBuilder<AppResult<List<MemberSummary>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(message: 'Caricamento persone...');
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
              final filteredMembers = _applyFilters(data);

              return RefreshIndicator(
                onRefresh: () async {
                  _reload();
                  await _future;
                },
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _QuickActionsCard(
                      totalMembers: data.length,
                      onInvitePressed: _goToCreateInvitation,
                      onInvitationsPressed: _goToInvitations,
                      onAssignTeamPressed: _goToAssignTeam,
                      onLinkParentPressed: _goToLinkParent,
                      onLinkAthletePressed: _goToLinkAthleteAccount,
                    ),
                    const SizedBox(height: 12),
                    _FiltersCard(
                      searchController: _searchController,
                      roleFilter: _roleFilter,
                      onSearchChanged: (value) {
                        setState(() {
                          _query = value;
                        });
                      },
                      onRoleFilterChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _roleFilter = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (filteredMembers.isEmpty)
                      _NoMembersCard(
                        hasFilters:
                            _query.trim().isNotEmpty || _roleFilter != 'all',
                        onInvitePressed: _goToCreateInvitation,
                      )
                    else
                      for (final member in filteredMembers) ...[
                        _MemberCard(member: member),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreateInvitation,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Invita'),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.totalMembers,
    required this.onInvitePressed,
    required this.onInvitationsPressed,
    required this.onAssignTeamPressed,
    required this.onLinkParentPressed,
    required this.onLinkAthletePressed,
  });

  final int totalMembers;
  final VoidCallback onInvitePressed;
  final VoidCallback onInvitationsPressed;
  final VoidCallback onAssignTeamPressed;
  final VoidCallback onLinkParentPressed;
  final VoidCallback onLinkAthletePressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Persone collegate: $totalMembers',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Gestisci account, ruoli e collegamenti operativi del club.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF52616B)),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onInvitePressed,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Nuovo invito'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onInvitationsPressed,
              icon: const Icon(Icons.mark_email_read_outlined),
              label: const Text('Gestisci inviti'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onAssignTeamPressed,
              icon: const Icon(Icons.groups_2_outlined),
              label: const Text('Assegna persona a squadra'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onLinkParentPressed,
              icon: const Icon(Icons.family_restroom_outlined),
              label: const Text('Collega genitore ad atleta'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onLinkAthletePressed,
              icon: const Icon(Icons.directions_run_outlined),
              label: const Text('Collega account atleta'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.searchController,
    required this.roleFilter,
    required this.onSearchChanged,
    required this.onRoleFilterChanged,
  });

  final TextEditingController searchController;
  final String roleFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onRoleFilterChanged;

  @override
  Widget build(BuildContext context) {
    const filters = [
      _RoleFilterOption(value: 'all', label: 'Tutti'),
      _RoleFilterOption(value: 'owner', label: 'Proprietario'),
      _RoleFilterOption(value: 'admin', label: 'Admin'),
      _RoleFilterOption(value: 'team_manager', label: 'Manager'),
      _RoleFilterOption(value: 'coach', label: 'Allenatore'),
      _RoleFilterOption(value: 'staff', label: 'Staff'),
      _RoleFilterOption(value: 'athlete', label: 'Atleta'),
      _RoleFilterOption(value: 'parent', label: 'Genitore/Tutore'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Cerca persona',
                hintText: 'Nome, email, squadra, atleta...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 14),
            Text(
              'Filtro ruolo',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in filters)
                  ChoiceChip(
                    label: Text(filter.label),
                    selected: roleFilter == filter.value,
                    onSelected: (_) => onRoleFilterChanged(filter.value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleFilterOption {
  const _RoleFilterOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _NoMembersCard extends StatelessWidget {
  const _NoMembersCard({
    required this.hasFilters,
    required this.onInvitePressed,
  });

  final bool hasFilters;
  final VoidCallback onInvitePressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(
              hasFilters
                  ? Icons.search_off_outlined
                  : Icons.people_alt_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilters ? 'Nessun risultato' : 'Nessuna persona collegata',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Modifica ricerca o filtro ruolo.'
                  : 'Invita utenti per popolare la rubrica accessi del club.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF52616B)),
            ),
            if (!hasFilters) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onInvitePressed,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Nuovo invito'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final MemberSummary member;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              child: Text(member.initials),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    member.email.isEmpty
                        ? 'Email non disponibile'
                        : member.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF52616B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.badge_outlined, size: 18),
                        label: Text(member.roleLabel),
                      ),
                      Chip(
                        avatar: const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                        ),
                        label: Text(member.statusLabel),
                      ),
                    ],
                  ),
                  if (member.teamAssignments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Squadre',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final assignment in member.teamAssignments)
                          Chip(
                            avatar: const Icon(
                              Icons.groups_2_outlined,
                              size: 18,
                            ),
                            label: Text(
                              '${assignment.teamName} · ${assignment.roleLabel}',
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (member.parentRelations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Atleti collegati',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final relation in member.parentRelations)
                          Chip(
                            avatar: const Icon(
                              Icons.family_restroom_outlined,
                              size: 18,
                            ),
                            label: Text(
                              '${relation.athleteName} · ${relation.relationLabel}',
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
