import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/permissions/club_role.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../clubs/domain/club_membership_summary.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../domain/team_detail.dart';
import 'team_providers.dart';

class TeamDetailScreen extends ConsumerStatefulWidget {
  const TeamDetailScreen({super.key, required this.teamId});

  final String teamId;

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen> {
  late Future<AppResult<_TeamDetailData>> _future;

  bool _isArchiving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AppResult<_TeamDetailData>> _load() async {
    final teamResult = await ref
        .read(teamRepositoryProvider)
        .fetchTeamById(teamId: widget.teamId);

    switch (teamResult) {
      case AppFailure(:final message, :final code):
        return AppFailure(message, code: code);

      case AppSuccess(data: final team):
        final membershipsResult = await ref
            .read(clubContextRepositoryProvider)
            .fetchMyClubMemberships();

        switch (membershipsResult) {
          case AppFailure(:final message, :final code):
            return AppFailure(message, code: code);

          case AppSuccess(data: final memberships):
            final matches = memberships.where(
              (membership) => membership.clubId == team.clubId,
            );

            if (matches.isEmpty) {
              return const AppFailure(
                'Non hai accesso a questa squadra.',
                code: 'team_membership_not_found',
              );
            }

            return AppSuccess(
              _TeamDetailData(team: team, membership: matches.first),
            );
        }
    }
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  void _goToEdit() {
    context.push('/teams/${widget.teamId}/edit').then((_) => _reload());
  }

  bool _canManageTeam(ClubMembershipSummary membership) {
    return membership.role == ClubRole.owner ||
        membership.role == ClubRole.admin ||
        membership.role == ClubRole.teamManager;
  }

  Future<void> _confirmArchive(_TeamDetailData data) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Archivia squadra'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Archiviando “${data.team.name}” la squadra verrà tolta dalle liste operative. Lo storico resterà conservato.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motivo facoltativo',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Archivia'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      reasonController.dispose();
      return;
    }

    setState(() {
      _isArchiving = true;
    });

    final result = await ref
        .read(teamRepositoryProvider)
        .archiveTeam(teamId: widget.teamId, reason: reasonController.text);

    reasonController.dispose();

    if (!mounted) {
      return;
    }

    setState(() {
      _isArchiving = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Squadra archiviata correttamente.')),
        );
        context.go('/teams');

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppResult<_TeamDetailData>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: AppLoadingView(message: 'Caricamento squadra...'),
          );
        }

        final result = snapshot.data;

        if (result == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dettaglio squadra')),
            body: AppErrorView(
              message: 'Risposta non valida durante il caricamento.',
              onRetry: _reload,
            ),
          );
        }

        switch (result) {
          case AppFailure(:final message):
            return Scaffold(
              appBar: AppBar(title: const Text('Dettaglio squadra')),
              body: AppErrorView(message: message, onRetry: _reload),
            );

          case AppSuccess(:final data):
            final team = data.team;
            final canManage = _canManageTeam(data.membership);

            return Scaffold(
              appBar: AppBar(
                title: const Text('Dettaglio squadra'),
                actions: [
                  if (canManage)
                    IconButton(
                      tooltip: 'Modifica',
                      onPressed: _goToEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                ],
              ),
              body: SafeArea(
                minimum: const EdgeInsets.all(24),
                child: ListView(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            Text('${team.sport} · ${team.genderLabel}'),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if ((team.category ?? '').isNotEmpty)
                                  Chip(label: Text(team.category!)),
                                if ((team.season ?? '').isNotEmpty)
                                  Chip(label: Text(team.season!)),
                                Chip(
                                  label: Text(
                                    team.isArchived ? 'Archiviata' : 'Attiva',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      title: 'Dati squadra',
                      rows: [
                        _InfoRow('Nome', team.name),
                        _InfoRow('Sport', team.sport),
                        _InfoRow('Categoria', team.category),
                        _InfoRow('Stagione', team.season),
                        _InfoRow('Anno nascita', team.birthYear?.toString()),
                        _InfoRow('Genere', team.genderLabel),
                        _InfoRow('Colore', team.color),
                        _InfoRow('Luogo allenamenti', team.trainingLocation),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Azioni squadra',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => context.push('/athletes'),
                              icon: const Icon(Icons.directions_run_outlined),
                              label: const Text('Vedi atleti'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/events'),
                              icon: const Icon(Icons.event_outlined),
                              label: const Text('Vedi eventi'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/invitations'),
                              icon: const Icon(Icons.person_add_alt_1_outlined),
                              label: const Text('Gestisci inviti'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (canManage)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Azioni amministrative',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _goToEdit,
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Modifica squadra'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _isArchiving || team.isArchived
                                    ? null
                                    : () => _confirmArchive(data),
                                icon: const Icon(Icons.archive_outlined),
                                label: Text(
                                  _isArchiving
                                      ? 'Archiviazione...'
                                      : 'Archivia squadra',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'L’archiviazione toglie la squadra dall’app operativa ma mantiene lo storico.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: const Color(0xFF52616B)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Text(
                            'Solo proprietari, amministratori e responsabili squadra possono modificare o archiviare la squadra.',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}

class _TeamDetailData {
  const _TeamDetailData({required this.team, required this.membership});

  final TeamDetail team;
  final ClubMembershipSummary membership;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows
        .where((row) => row.value != null && row.value!.trim().isNotEmpty)
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (visibleRows.isEmpty)
              const Text('Nessun dato disponibile.')
            else
              for (final row in visibleRows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          row.label,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Expanded(child: Text(row.value ?? '-')),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);

  final String label;
  final String? value;
}
