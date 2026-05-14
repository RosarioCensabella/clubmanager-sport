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

  bool _isArchiving = false;
  bool _isLinkingAccount = false;

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

      case AppSuccess(data: final athlete):
        final relationsResult = await repository.fetchParentRelations(
          athleteId: widget.athleteId,
        );

        switch (relationsResult) {
          case AppFailure(:final message, :final code):
            return AppFailure(message, code: code);

          case AppSuccess(data: final relations):
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

  void _goToEdit() {
    context.push('/athletes/${widget.athleteId}/edit').then((_) => _reload());
  }

  void _goToLinkParent() {
    context
        .push('/athletes/${widget.athleteId}/parents/link')
        .then((_) => _reload());
  }

  void _goToInvitations() {
    context.push('/invitations/create');
  }

  Future<void> _linkAthleteAccount(AthleteSummary athlete) async {
    final emailController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Collega account atleta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Inserisci l’email dell’account da collegare a ${athlete.fullName}.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email account atleta',
                  helperText:
                      'L’account deve esistere. Se non esiste, crea prima un invito come atleta.',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
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
              child: const Text('Collega'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      emailController.dispose();
      return;
    }

    setState(() {
      _isLinkingAccount = true;
    });

    final result = await ref
        .read(athleteRepositoryProvider)
        .linkAthleteAccountByEmail(
          athleteId: widget.athleteId,
          email: emailController.text,
        );

    emailController.dispose();

    if (!mounted) {
      return;
    }

    setState(() {
      _isLinkingAccount = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account atleta collegato.')),
        );
        _reload();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _confirmArchive(AthleteSummary athlete) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Archivia atleta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Archiviando “${athlete.fullName}” l’atleta verrà tolto dalle liste operative. Lo storico resterà conservato.',
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
        .read(athleteRepositoryProvider)
        .archiveAthlete(
          athleteId: widget.athleteId,
          reason: reasonController.text,
        );

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
          const SnackBar(content: Text('Atleta archiviato correttamente.')),
        );
        context.go('/athletes');

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _removeRelation(ParentRelationSummary relation) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rimuovere collegamento?'),
          content: Text(
            '${relation.parentFullName} non sarà più collegato a questo atleta.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
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
    return FutureBuilder<AppResult<_AthleteDetailData>>(
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

          case AppSuccess(data: final data):
            final athlete = data.athlete;

            return Scaffold(
              appBar: AppBar(
                title: Text(athlete.fullName),
                actions: [
                  IconButton(
                    tooltip: 'Modifica atleta',
                    onPressed: _goToEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
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
                    _AthleteInfoCard(athlete: athlete),
                    const SizedBox(height: 12),
                    _AccountLinkCard(
                      athlete: athlete,
                      isLoading: _isLinkingAccount,
                      onLinkPressed: () => _linkAthleteAccount(athlete),
                      onInvitePressed: _goToInvitations,
                    ),
                    const SizedBox(height: 12),
                    _ParentsCard(
                      relations: data.parentRelations,
                      onAddPressed: _goToLinkParent,
                      onRemovePressed: _removeRelation,
                    ),
                    const SizedBox(height: 12),
                    _AdministrativeActionsCard(
                      isArchiving: _isArchiving,
                      onEditPressed: _goToEdit,
                      onArchivePressed: athlete.active
                          ? () => _confirmArchive(athlete)
                          : null,
                    ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _goToEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modifica'),
              ),
            );
        }
      },
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(athlete.active ? 'Attivo' : 'Non attivo'),
                  avatar: Icon(
                    athlete.active
                        ? Icons.check_circle_outline
                        : Icons.archive_outlined,
                    size: 18,
                  ),
                ),
                Chip(
                  label: Text(athlete.medicalCertificateStatusLabel),
                  avatar: const Icon(
                    Icons.medical_information_outlined,
                    size: 18,
                  ),
                ),
                if (athlete.userId != null && athlete.userId!.isNotEmpty)
                  const Chip(
                    label: Text('Account collegato'),
                    avatar: Icon(Icons.verified_user_outlined, size: 18),
                  )
                else
                  const Chip(
                    label: Text('Account non collegato'),
                    avatar: Icon(Icons.link_off_outlined, size: 18),
                  ),
              ],
            ),
            const Divider(height: 28),
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
              label: 'Squadra',
              value: athlete.teamName?.isNotEmpty == true
                  ? athlete.teamName!
                  : 'Nessuna squadra',
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
            _InfoRow(
              label: 'Account atleta',
              value: athlete.userId?.isNotEmpty == true
                  ? 'Collegato'
                  : 'Non collegato',
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

class _AccountLinkCard extends StatelessWidget {
  const _AccountLinkCard({
    required this.athlete,
    required this.isLoading,
    required this.onLinkPressed,
    required this.onInvitePressed,
  });

  final AthleteSummary athlete;
  final bool isLoading;
  final VoidCallback onLinkPressed;
  final VoidCallback onInvitePressed;

  @override
  Widget build(BuildContext context) {
    final hasAccount = athlete.userId != null && athlete.userId!.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  hasAccount
                      ? Icons.verified_user_outlined
                      : Icons.link_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Account atleta',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              hasAccount
                  ? 'Questo atleta è già collegato a un account utente. Quando l’utente accede, potrà vedere le informazioni collegate al suo profilo atleta.'
                  : 'Collega l’atleta a un account utente esistente. Se l’account non esiste, crea prima un invito con ruolo atleta.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF52616B)),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isLoading ? null : onLinkPressed,
              icon: const Icon(Icons.link_outlined),
              label: Text(
                isLoading
                    ? 'Collegamento...'
                    : hasAccount
                    ? 'Cambia account collegato'
                    : 'Collega account atleta',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onInvitePressed,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Crea invito atleta'),
            ),
          ],
        ),
      ),
    );
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

class _AdministrativeActionsCard extends StatelessWidget {
  const _AdministrativeActionsCard({
    required this.isArchiving,
    required this.onEditPressed,
    required this.onArchivePressed,
  });

  final bool isArchiving;
  final VoidCallback onEditPressed;
  final VoidCallback? onArchivePressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Azioni amministrative',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onEditPressed,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifica atleta'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isArchiving ? null : onArchivePressed,
              icon: const Icon(Icons.archive_outlined),
              label: Text(isArchiving ? 'Archiviazione...' : 'Archivia atleta'),
            ),
            const SizedBox(height: 8),
            Text(
              'L’archiviazione toglie l’atleta dalle liste operative ma mantiene lo storico.',
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
