import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../domain/athlete_summary.dart';
import '../domain/parent_relation_summary.dart';
import 'athlete_providers.dart';

class AthleteDetailScreen extends ConsumerStatefulWidget {
  const AthleteDetailScreen({super.key, required this.athleteId});

  final String athleteId;

  @override
  ConsumerState<AthleteDetailScreen> createState() =>
      _AthleteDetailScreenState();
}

class _AthleteDetailScreenState extends ConsumerState<AthleteDetailScreen> {
  late Future<AppResult<_AthleteDetailData>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDetail();
  }

  Future<AppResult<_AthleteDetailData>> _loadDetail() async {
    final repository = ref.read(athleteRepositoryProvider);

    final athleteResult = await repository.fetchAthleteById(
      athleteId: widget.athleteId,
    );

    switch (athleteResult) {
      case AppFailure(:final message, :final code):
        return AppFailure(message, code: code);

      case AppSuccess(:final data):
        final athlete = data;

        final relationsResult = await repository.fetchParentRelations(
          athleteId: widget.athleteId,
        );

        switch (relationsResult) {
          case AppFailure(:final message, :final code):
            return AppFailure(message, code: code);

          case AppSuccess(:final data):
            final relations = data;

            return AppSuccess(
              _AthleteDetailData(athlete: athlete, parentRelations: relations),
            );
        }
    }
  }

  void _reload() {
    setState(() {
      _future = _loadDetail();
    });
  }

  void _goToLinkParent() {
    context
        .push('/athletes/${widget.athleteId}/parents/link')
        .then((_) => _reload());
  }

  Future<void> _removeRelation(ParentRelationSummary relation) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rimuovere collegamento?'),
          content: Text(
            '${relation.parentFullName} non sarà più collegato a questo atleta.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Rimuovi'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) {
      return;
    }

    final result = await ref
        .read(athleteRepositoryProvider)
        .removeParentRelation(relationId: relation.id);

    if (!mounted) {
      return;
    }

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Collegamento rimosso.')));
        _reload();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<AppResult<_AthleteDetailData>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: AppLoadingView(message: 'Caricamento dettaglio atleta...'),
            );
          }

          final result = snapshot.data;

          if (result == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Dettaglio atleta')),
              body: AppErrorView(
                message: 'Risposta non valida durante il caricamento.',
                onRetry: _reload,
              ),
            );
          }

          switch (result) {
            case AppFailure(:final message):
              return Scaffold(
                appBar: AppBar(title: const Text('Dettaglio atleta')),
                body: AppErrorView(message: message, onRetry: _reload),
              );

            case AppSuccess(:final data):
              return Scaffold(
                appBar: AppBar(
                  title: Text(data.athlete.fullName),
                  actions: [
                    IconButton(
                      tooltip: 'Collega genitore/tutore',
                      onPressed: _goToLinkParent,
                      icon: const Icon(Icons.family_restroom_outlined),
                    ),
                  ],
                ),
                body: RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    await _future;
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _AthleteInfoCard(athlete: data.athlete),
                      const SizedBox(height: 12),
                      _ParentsCard(
                        relations: data.parentRelations,
                        onAddPressed: _goToLinkParent,
                        onRemovePressed: _removeRelation,
                      ),
                    ],
                  ),
                ),
                floatingActionButton: FloatingActionButton.extended(
                  onPressed: _goToLinkParent,
                  icon: const Icon(Icons.family_restroom_outlined),
                  label: const Text('Collega tutore'),
                ),
              );
          }
        },
      ),
    );
  }
}

class _AthleteDetailData {
  const _AthleteDetailData({
    required this.athlete,
    required this.parentRelations,
  });

  final AthleteSummary athlete;
  final List<ParentRelationSummary> parentRelations;
}

class _AthleteInfoCard extends StatelessWidget {
  const _AthleteInfoCard({required this.athlete});

  final AthleteSummary athlete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  child: Text(athlete.initials),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        athlete.fullName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        athlete.teamName ?? 'Nessuna squadra collegata',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF52616B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _InfoRow(
              label: 'Data di nascita',
              value: athlete.dateOfBirth == null
                  ? 'Non indicata'
                  : _formatDate(athlete.dateOfBirth!),
            ),
            _InfoRow(
              label: 'Numero maglia',
              value: athlete.jerseyNumber?.isNotEmpty == true
                  ? athlete.jerseyNumber!
                  : 'Non indicato',
            ),
            _InfoRow(
              label: 'Ruolo sportivo',
              value: athlete.sportRole?.isNotEmpty == true
                  ? athlete.sportRole!
                  : 'Non indicato',
            ),
            _InfoRow(
              label: 'Certificato medico',
              value: athlete.medicalCertificateStatusLabel,
            ),
            _InfoRow(
              label: 'Scadenza certificato',
              value: athlete.medicalCertificateExpiry == null
                  ? 'Non indicata'
                  : _formatDate(athlete.medicalCertificateExpiry!),
            ),
            if (athlete.staffNotes != null &&
                athlete.staffNotes!.trim().isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                'Note staff private',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                athlete.staffNotes!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');

    return '$day/$month/$year';
  }
}

class _ParentsCard extends StatelessWidget {
  const _ParentsCard({
    required this.relations,
    required this.onAddPressed,
    required this.onRemovePressed,
  });

  final List<ParentRelationSummary> relations;
  final VoidCallback onAddPressed;
  final ValueChanged<ParentRelationSummary> onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.family_restroom_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Genitori e tutori',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddPressed,
                  icon: const Icon(Icons.add),
                  label: const Text('Collega'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (relations.isEmpty)
              Text(
                'Nessun genitore o tutore collegato a questo atleta.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF52616B),
                ),
              )
            else
              for (final relation in relations) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(relation.parentFullName),
                  subtitle: Text(
                    '${relation.relationLabel} · ${relation.parentEmail}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Rimuovi',
                    onPressed: () => onRemovePressed(relation),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
                if (relation != relations.last) const Divider(),
              ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF52616B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
