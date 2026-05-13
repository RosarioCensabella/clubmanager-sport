import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/permissions/app_permission.dart';
import '../../../core/permissions/permission_policy.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../domain/club_membership_summary.dart';
import 'club_context_providers.dart';

class ClubWorkspaceScreen extends ConsumerStatefulWidget {
  const ClubWorkspaceScreen({super.key, required this.clubId});

  final String clubId;

  @override
  ConsumerState<ClubWorkspaceScreen> createState() =>
      _ClubWorkspaceScreenState();
}

class _ClubWorkspaceScreenState extends ConsumerState<ClubWorkspaceScreen> {
  late Future<AppResult<ClubMembershipSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadWorkspace();
  }

  Future<AppResult<ClubMembershipSummary>> _loadWorkspace() async {
    final repository = ref.read(clubContextRepositoryProvider);
    final result = await repository.fetchMyClubMemberships();

    switch (result) {
      case AppFailure(:final message, :final code):
        return AppFailure(message, code: code);

      case AppSuccess(:final data):
        final matches = data.where(
          (membership) => membership.clubId == widget.clubId,
        );

        if (matches.isEmpty) {
          return const AppFailure(
            'Non hai accesso a questo club oppure il club non è più disponibile.',
            code: 'club_workspace_not_found',
          );
        }

        final membership = matches.first;
        await repository.setActiveClubId(membership.clubId);

        return AppSuccess(membership);
    }
  }

  void _reload() {
    setState(() {
      _future = _loadWorkspace();
    });
  }

  void _goToClubSelection() {
    context.go('/club-context');
  }

  void _goToProfile() {
    context.push('/profile');
  }

  void _goToSettings() {
    context.push('/settings');
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppResult<ClubMembershipSummary>>(
      future: _future,
      builder: (context, snapshot) {
        final result = snapshot.data;

        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: AppLoadingView(message: 'Caricamento workspace club...'),
          );
        }

        if (result == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Workspace club')),
            body: AppErrorView(
              message: 'Risposta non valida durante il caricamento.',
              onRetry: _reload,
            ),
          );
        }

        switch (result) {
          case AppFailure(:final message):
            return Scaffold(
              appBar: AppBar(title: const Text('Workspace club')),
              body: AppErrorView(message: message, onRetry: _reload),
            );

          case AppSuccess(:final data):
            final permissions = PermissionPolicy.allowedPermissionsFor(
              data.role,
            );

            return Scaffold(
              appBar: AppBar(
                title: Text(data.club.name),
                actions: [
                  IconButton(
                    tooltip: 'Cambia club',
                    onPressed: _goToClubSelection,
                    icon: const Icon(Icons.swap_horiz_outlined),
                  ),
                  IconButton(
                    tooltip: 'Profilo',
                    onPressed: _goToProfile,
                    icon: const Icon(Icons.account_circle_outlined),
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  _reload();
                  await _future;
                },
                child: SafeArea(
                  minimum: const EdgeInsets.all(24),
                  child: ListView(
                    children: [
                      _WorkspaceHeaderCard(membership: data),
                      const SizedBox(height: 12),
                      _ManagementGrid(
                        onTeamsPressed: _goToTeams,
                        onAthletesPressed: _goToAthletes,
                        onInvitationsPressed: _goToInvitations,
                        onEventsPressed: _goToEvents,
                        onCommunicationsPressed: _goToCommunications,
                        onDocumentsPressed: _goToDocuments,
                        onFeesPressed: _goToFees,
                      ),
                      const SizedBox(height: 12),
                      _ClubOperationsCard(
                        onClubSelectionPressed: _goToClubSelection,
                        onSettingsPressed: _goToSettings,
                      ),
                      const SizedBox(height: 12),
                      _PermissionsCard(permissions: permissions),
                    ],
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}

class _WorkspaceHeaderCard extends StatelessWidget {
  const _WorkspaceHeaderCard({required this.membership});

  final ClubMembershipSummary membership;

  @override
  Widget build(BuildContext context) {
    final club = membership.club;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              child: Text(
                _firstLetter(club.name),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${club.sportPrimary} · ${club.city}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF52616B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.badge_outlined, size: 18),
                        label: Text(membership.role.label),
                      ),
                      const Chip(
                        avatar: Icon(Icons.check_circle_outline, size: 18),
                        label: Text('Club attivo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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

class _ManagementGrid extends StatelessWidget {
  const _ManagementGrid({
    required this.onTeamsPressed,
    required this.onAthletesPressed,
    required this.onInvitationsPressed,
    required this.onEventsPressed,
    required this.onCommunicationsPressed,
    required this.onDocumentsPressed,
    required this.onFeesPressed,
  });

  final VoidCallback onTeamsPressed;
  final VoidCallback onAthletesPressed;
  final VoidCallback onInvitationsPressed;
  final VoidCallback onEventsPressed;
  final VoidCallback onCommunicationsPressed;
  final VoidCallback onDocumentsPressed;
  final VoidCallback onFeesPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestione club',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Scegli l’area su cui vuoi lavorare per questo club.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF52616B)),
            ),
            const SizedBox(height: 16),
            _WorkspaceActionTile(
              icon: Icons.groups_2_outlined,
              title: 'Squadre',
              subtitle: 'Gestisci squadre, staff e assegnazioni.',
              onTap: onTeamsPressed,
            ),
            _WorkspaceActionTile(
              icon: Icons.directions_run_outlined,
              title: 'Atleti',
              subtitle: 'Anagrafiche, tutori, squadre e dettagli atleta.',
              onTap: onAthletesPressed,
            ),
            _WorkspaceActionTile(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Inviti e accessi',
              subtitle: 'Invita utenti e prepara accessi controllati.',
              onTap: onInvitationsPressed,
            ),
            _WorkspaceActionTile(
              icon: Icons.event_outlined,
              title: 'Eventi e convocazioni',
              subtitle: 'Calendario, partite, allenamenti e RSVP.',
              onTap: onEventsPressed,
            ),
            _WorkspaceActionTile(
              icon: Icons.fact_check_outlined,
              title: 'Presenze',
              subtitle: 'Apri le presenze dai dettagli evento.',
              onTap: onEventsPressed,
            ),
            _WorkspaceActionTile(
              icon: Icons.campaign_outlined,
              title: 'Comunicazioni',
              subtitle: 'Avvisi e messaggi operativi del club.',
              onTap: onCommunicationsPressed,
            ),
            _WorkspaceActionTile(
              icon: Icons.folder_copy_outlined,
              title: 'Documenti e scadenze',
              subtitle: 'Certificati, file e promemoria documentali.',
              onTap: onDocumentsPressed,
            ),
            _WorkspaceActionTile(
              icon: Icons.payments_outlined,
              title: 'Quote associative',
              subtitle: 'Quote, assegnazioni e pagamenti parziali.',
              onTap: onFeesPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceActionTile extends StatelessWidget {
  const _WorkspaceActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0E6ED)),
        ),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ClubOperationsCard extends StatelessWidget {
  const _ClubOperationsCard({
    required this.onClubSelectionPressed,
    required this.onSettingsPressed,
  });

  final VoidCallback onClubSelectionPressed;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Contesto e account',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onClubSelectionPressed,
              icon: const Icon(Icons.swap_horiz_outlined),
              label: const Text('Cambia club'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onSettingsPressed,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Impostazioni account'),
            ),
            const SizedBox(height: 12),
            Text(
              'La modifica dati club, archiviazione club e gestione membri saranno completate nella fase dedicata alla gestione club.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF52616B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard({required this.permissions});

  final List<AppPermission> permissions;

  @override
  Widget build(BuildContext context) {
    final visiblePermissions = permissions.take(12).toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permessi nel club',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (visiblePermissions.isEmpty)
              const Text('Nessun permesso operativo disponibile.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final permission in visiblePermissions)
                    Chip(label: Text(permission.label)),
                  if (permissions.length > visiblePermissions.length)
                    Chip(
                      label: Text(
                        '+${permissions.length - visiblePermissions.length}',
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
