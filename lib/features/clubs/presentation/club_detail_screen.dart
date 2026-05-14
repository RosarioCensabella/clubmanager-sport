import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../domain/club_management_data.dart';
import 'club_context_providers.dart';

class ClubDetailScreen extends ConsumerStatefulWidget {
  const ClubDetailScreen({super.key, required this.clubId});

  final String clubId;

  @override
  ConsumerState<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends ConsumerState<ClubDetailScreen> {
  late Future<AppResult<ClubManagementData>> _future;

  bool _isArchiving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AppResult<ClubManagementData>> _load() {
    return ref
        .read(clubContextRepositoryProvider)
        .fetchClubManagementData(clubId: widget.clubId);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  void _goToEdit() {
    context.push('/clubs/${widget.clubId}/edit').then((_) => _reload());
  }

  void _goToWorkspace() {
    context.go('/clubs/${widget.clubId}/workspace');
  }

  Future<void> _confirmArchive(ClubManagementData data) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Archivia club'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Archiviando “${data.club.name}” il club verrà tolto dalle liste operative. Lo storico resterà conservato.',
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
        .read(clubContextRepositoryProvider)
        .archiveClub(clubId: widget.clubId, reason: reasonController.text);

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
          const SnackBar(content: Text('Club archiviato correttamente.')),
        );
        context.go('/club-context');

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppResult<ClubManagementData>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: AppLoadingView(message: 'Caricamento club...'),
          );
        }

        final result = snapshot.data;

        if (result == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Gestione club')),
            body: AppErrorView(
              message: 'Risposta non valida durante il caricamento.',
              onRetry: _reload,
            ),
          );
        }

        switch (result) {
          case AppFailure(:final message):
            return Scaffold(
              appBar: AppBar(title: const Text('Gestione club')),
              body: AppErrorView(message: message, onRetry: _reload),
            );

          case AppSuccess(:final data):
            final club = data.club;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Gestione club'),
                actions: [
                  IconButton(
                    tooltip: 'Workspace',
                    onPressed: _goToWorkspace,
                    icon: const Icon(Icons.dashboard_customize_outlined),
                  ),
                  if (data.canManageClub)
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
                              club.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            Text('${club.sportPrimary} · ${club.city}'),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(label: Text(data.membership.role.label)),
                                Chip(
                                  label: Text(
                                    club.isArchived ? 'Archiviato' : 'Attivo',
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
                      title: 'Dati principali',
                      rows: [
                        _InfoRow('Sport', club.sportPrimary),
                        _InfoRow('Città', club.city),
                        _InfoRow('Stagione', club.season),
                        _InfoRow('Email', club.email),
                        _InfoRow('Telefono', club.phone),
                        _InfoRow('Sito web', club.website),
                        _InfoRow('Indirizzo', club.address),
                        _InfoRow('Codice fiscale / P. IVA', club.fiscalCode),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      title: 'Piano e stato',
                      rows: [
                        _InfoRow('Piano', club.subscriptionPlan),
                        _InfoRow('Stato abbonamento', club.subscriptionStatus),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (data.canManageClub)
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
                                label: const Text('Modifica dati club'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _isArchiving || club.isArchived
                                    ? null
                                    : () => _confirmArchive(data),
                                icon: const Icon(Icons.archive_outlined),
                                label: Text(
                                  _isArchiving
                                      ? 'Archiviazione...'
                                      : 'Archivia club',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'L’archiviazione toglie il club dall’app operativa ma mantiene lo storico.',
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
                            'Solo proprietari e amministratori possono modificare o archiviare il club.',
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
                        width: 140,
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
