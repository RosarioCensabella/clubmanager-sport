import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/permissions/app_permission.dart';
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

  Future<void> _openWorkspace(ClubMembershipSummary membership) async {
    await ref
        .read(clubContextRepositoryProvider)
        .setActiveClubId(membership.clubId);

    if (!mounted) {
      return;
    }

    context.go('/clubs/${membership.clubId}/workspace');
  }

  void _goToCreateClub() {
    context.push('/clubs/create').then((_) => _reload());
  }

  void _goToProfile() {
    context.push('/profile');
  }

  bool get _hasActiveClub => _activeClubId != null && _activeClubId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleziona club'),
        actions: [
          IconButton(
            tooltip: 'Profilo utente',
            onPressed: _goToProfile,
            icon: const Icon(Icons.account_circle_outlined),
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
              message: 'Caricamento club disponibili...',
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
                      );
                    }

                    if (index == 1) {
                      return _ContextInfoCard(
                        onProfilePressed: _goToProfile,
                        onCreateClubPressed: _goToCreateClub,
                      );
                    }

                    final membership = data[index - 2];

                    return _ClubMembershipCard(
                      membership: membership,
                      isActive: membership.clubId == _activeClubId,
                      onOpenWorkspace: () => _openWorkspace(membership),
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
  });

  final int membershipsCount;
  final bool hasActiveClub;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.business_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scegli il club su cui lavorare',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
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
                      'Apri un club per entrare nel suo workspace gestionale.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFC62828),
                      ),
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

class _ContextInfoCard extends StatelessWidget {
  const _ContextInfoCard({
    required this.onProfilePressed,
    required this.onCreateClubPressed,
  });

  final VoidCallback onProfilePressed;
  final VoidCallback onCreateClubPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Workspace multi-club',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Ogni club ha un workspace separato. Da lì gestisci squadre, atleti, inviti, eventi, documenti, quote e comunicazioni.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF52616B)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onProfilePressed,
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('Profilo utente'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onCreateClubPressed,
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Crea nuovo club'),
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
    required this.onOpenWorkspace,
  });

  final ClubMembershipSummary membership;
  final bool isActive;
  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    final permissions = PermissionPolicy.allowedPermissionsFor(membership.role);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpenWorkspace,
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
                    child: Text(_firstLetter(membership.club.name)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          membership.club.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
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
                  const Icon(Icons.chevron_right),
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
                      label: Text('Ultimo club attivo'),
                      avatar: Icon(Icons.check, size: 18),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Permessi principali',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              _PermissionsPreview(permissions: permissions),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onOpenWorkspace,
                icon: const Icon(Icons.dashboard_customize_outlined),
                label: const Text('Apri workspace'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _firstLetter(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return '?';
    }

    return trimmed.substring(0, 1).toUpperCase();
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
