import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/permissions/app_permission.dart';
import '../../../core/permissions/club_role.dart';
import '../../../core/permissions/permission_policy.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../domain/club_membership_summary.dart';
import 'club_context_providers.dart';

class ClubContextScreen extends ConsumerStatefulWidget {
  const ClubContextScreen({super.key});

  @override
  ConsumerState<ClubContextScreen> createState() => _ClubContextScreenState();
}

class _ClubContextScreenState extends ConsumerState<ClubContextScreen> {
  late Future<AppResult<List<ClubMembershipSummary>>> _future;

  String? _activeClubId;

  @override
  void initState() {
    super.initState();
    _future = _loadMemberships();
  }

  Future<AppResult<List<ClubMembershipSummary>>> _loadMemberships() async {
    final repository = ref.read(clubContextRepositoryProvider);
    _activeClubId = await repository.getActiveClubId();

    return repository.fetchMyClubMemberships();
  }

  void _reload() {
    setState(() {
      _future = _loadMemberships();
    });
  }

  Future<void> _selectClub(ClubMembershipSummary membership) async {
    await ref
        .read(clubContextRepositoryProvider)
        .setActiveClubId(membership.clubId);

    if (!mounted) {
      return;
    }

    setState(() {
      _activeClubId = membership.clubId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Club attivo: ${membership.club.name}')),
    );
  }

  void _goToCreateClub() {
    context.push('/clubs/create').then((_) => _reload());
  }

  void _goToTeams() {
    context.push('/teams');
  }

  bool get _hasActiveClub => _activeClubId != null && _activeClubId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Club e permessi'),
        actions: [
          IconButton(
            tooltip: 'Squadre',
            onPressed: _hasActiveClub ? _goToTeams : null,
            icon: const Icon(Icons.groups_2_outlined),
          ),
          IconButton(
            tooltip: 'Crea club',
            onPressed: _goToCreateClub,
            icon: const Icon(Icons.add_business_outlined),
          ),
        ],
      ),
      body: FutureBuilder<AppResult<List<ClubMembershipSummary>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(
              message: 'Caricamento club e permessi...',
            );
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
              if (data.isEmpty) {
                return AppEmptyState(
                  icon: Icons.shield_outlined,
                  title: 'Nessun club collegato',
                  message:
                      'Il tuo account è attivo, ma non appartieni ancora a un club. Puoi creare il tuo club o accettare un invito.',
                  actionLabel: 'Crea club',
                  onActionPressed: _goToCreateClub,
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _reload();
                  await _future;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: data.length + 2,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _HeaderCard(
                        membershipsCount: data.length,
                        hasActiveClub: _hasActiveClub,
                        onTeamsPressed: _hasActiveClub ? _goToTeams : null,
                      );
                    }

                    if (index == 1) {
                      return _QuickActionsCard(
                        hasActiveClub: _hasActiveClub,
                        onCreateClubPressed: _goToCreateClub,
                        onTeamsPressed: _hasActiveClub ? _goToTeams : null,
                      );
                    }

                    final membership = data[index - 2];

                    return _ClubMembershipCard(
                      membership: membership,
                      isActive: membership.clubId == _activeClubId,
                      onSelect: () => _selectClub(membership),
                    );
                  },
                ),
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreateClub,
        icon: const Icon(Icons.add),
        label: const Text('Crea club'),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.membershipsCount,
    required this.hasActiveClub,
    required this.onTeamsPressed,
  });

  final int membershipsCount;
  final bool hasActiveClub;
  final VoidCallback? onTeamsPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accesso verificato',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    membershipsCount == 1
                        ? 'Hai 1 club collegato al tuo account.'
                        : 'Hai $membershipsCount club collegati al tuo account.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF52616B),
                    ),
                  ),
                  if (!hasActiveClub) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Seleziona un club per gestire squadre, membri ed eventi.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFC62828),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Squadre',
              onPressed: onTeamsPressed,
              icon: const Icon(Icons.groups_2_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.hasActiveClub,
    required this.onCreateClubPressed,
    required this.onTeamsPressed,
  });

  final bool hasActiveClub;
  final VoidCallback onCreateClubPressed;
  final VoidCallback? onTeamsPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Azioni rapide',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onCreateClubPressed,
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Crea nuovo club'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: hasActiveClub ? onTeamsPressed : null,
              icon: const Icon(Icons.groups_2_outlined),
              label: const Text('Gestisci squadre'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubMembershipCard extends StatelessWidget {
  const _ClubMembershipCard({
    required this.membership,
    required this.isActive,
    required this.onSelect,
  });

  final ClubMembershipSummary membership;
  final bool isActive;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final permissions = PermissionPolicy.allowedPermissionsFor(membership.role);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    child: Text(
                      membership.club.name.isEmpty
                          ? '?'
                          : membership.club.name.characters.first,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          membership.club.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${membership.club.sportPrimary} · ${membership.club.city}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF52616B)),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(membership.role.label),
                    avatar: const Icon(Icons.badge_outlined, size: 18),
                  ),
                  if (isActive)
                    const Chip(
                      label: Text('Club attivo'),
                      avatar: Icon(Icons.check, size: 18),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Permessi principali',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _PermissionsPreview(permissions: permissions),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionsPreview extends StatelessWidget {
  const _PermissionsPreview({required this.permissions});

  final List<AppPermission> permissions;

  @override
  Widget build(BuildContext context) {
    final visiblePermissions = permissions.take(6).toList(growable: false);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final permission in visiblePermissions)
          Chip(label: Text(permission.label)),
        if (permissions.length > visiblePermissions.length)
          Chip(
            label: Text('+${permissions.length - visiblePermissions.length}'),
          ),
      ],
    );
  }
}
