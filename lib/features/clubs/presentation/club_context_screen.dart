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

  void _goToProfile() {
    context.push('/profile');
  }

  void _goToTeams() {
    context.push('/teams');
  }

  void _goToInvitations() {
    context.push('/invitations');
  }

  void _goToAthletes() {
    context.push('/athletes');
  }

  void _goToEvents() {
    context.push('/events');
  }

  void _goToCommunications() {
    context.push('/communications');
  }

  void _goToDocuments() {
    context.push('/documents');
  }

  void _goToFees() {
    context.push('/fees');
  }

  bool get _hasActiveClub => _activeClubId != null && _activeClubId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Club e permessi'),
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
                      );
                    }

                    if (index == 1) {
                      return _QuickActionsCard(
                        hasActiveClub: _hasActiveClub,
                        onProfilePressed: _goToProfile,
                        onCreateClubPressed: _goToCreateClub,
                        onTeamsPressed: _hasActiveClub ? _goToTeams : null,
                        onInvitationsPressed: _hasActiveClub
                            ? _goToInvitations
                            : null,
                        onAthletesPressed: _hasActiveClub
                            ? _goToAthletes
                            : null,
                        onEventsPressed: _hasActiveClub ? _goToEvents : null,
                        onCommunicationsPressed: _hasActiveClub
                            ? _goToCommunications
                            : null,
                        onDocumentsPressed: _hasActiveClub
                            ? _goToDocuments
                            : null,
                        onFeesPressed: _hasActiveClub ? _goToFees : null,
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
                      'Seleziona un club per abilitare squadre, atleti, eventi, comunicazioni, documenti e quote.',
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

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.hasActiveClub,
    required this.onProfilePressed,
    required this.onCreateClubPressed,
    required this.onTeamsPressed,
    required this.onInvitationsPressed,
    required this.onAthletesPressed,
    required this.onEventsPressed,
    required this.onCommunicationsPressed,
    required this.onDocumentsPressed,
    required this.onFeesPressed,
  });

  final bool hasActiveClub;
  final VoidCallback onProfilePressed;
  final VoidCallback onCreateClubPressed;
  final VoidCallback? onTeamsPressed;
  final VoidCallback? onInvitationsPressed;
  final VoidCallback? onAthletesPressed;
  final VoidCallback? onEventsPressed;
  final VoidCallback? onCommunicationsPressed;
  final VoidCallback? onDocumentsPressed;
  final VoidCallback? onFeesPressed;

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
            _ActionButton(
              label: 'Profilo utente',
              icon: Icons.account_circle_outlined,
              onPressed: onProfilePressed,
              primary: true,
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Quote associative',
              icon: Icons.payments_outlined,
              onPressed: hasActiveClub ? onFeesPressed : null,
              primary: true,
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Documenti e scadenze',
              icon: Icons.folder_copy_outlined,
              onPressed: hasActiveClub ? onDocumentsPressed : null,
              primary: true,
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Comunicazioni',
              icon: Icons.campaign_outlined,
              onPressed: hasActiveClub ? onCommunicationsPressed : null,
              primary: true,
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Calendario eventi',
              icon: Icons.event_outlined,
              onPressed: hasActiveClub ? onEventsPressed : null,
              primary: true,
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Gestisci atleti',
              icon: Icons.directions_run_outlined,
              onPressed: hasActiveClub ? onAthletesPressed : null,
              primary: true,
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Gestisci squadre',
              icon: Icons.groups_2_outlined,
              onPressed: hasActiveClub ? onTeamsPressed : null,
              primary: false,
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Gestisci inviti',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: hasActiveClub ? onInvitationsPressed : null,
              primary: false,
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Crea nuovo club',
              icon: Icons.add_business_outlined,
              onPressed: onCreateClubPressed,
              primary: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.primary,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
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
