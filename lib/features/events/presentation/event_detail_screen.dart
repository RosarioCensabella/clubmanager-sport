import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../callups/domain/callup_summary.dart';
import '../../callups/presentation/callup_providers.dart';
import '../domain/event_summary.dart';
import 'event_providers.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  late Future<AppResult<_EventDetailData>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDetail();
  }

  Future<AppResult<_EventDetailData>> _loadDetail() async {
    final eventRepository = ref.read(eventRepositoryProvider);
    final callupRepository = ref.read(callupRepositoryProvider);

    final eventResult = await eventRepository.fetchEventById(
      eventId: widget.eventId,
    );

    switch (eventResult) {
      case AppFailure(:final message, :final code):
        return AppFailure(message, code: code);

      case AppSuccess(:final data):
        final event = data;

        final callupsResult = await callupRepository.fetchCallupsForEvent(
          eventId: widget.eventId,
        );

        switch (callupsResult) {
          case AppFailure(:final message, :final code):
            return AppFailure(message, code: code);

          case AppSuccess(:final data):
            return AppSuccess(_EventDetailData(event: event, callups: data));
        }
    }
  }

  void _reload() {
    setState(() {
      _future = _loadDetail();
    });
  }

  void _goToAddCallups(EventSummary event) {
    context.push('/events/${event.id}/callups/add').then((_) => _reload());
  }

  Future<void> _removeCallup(CallupSummary callup) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rimuovere convocazione?'),
          content: Text(
            '${callup.athlete.fullName} verrà rimosso dalla convocazione.',
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
        .read(callupRepositoryProvider)
        .removeCallup(callupId: callup.id);

    if (!mounted) {
      return;
    }

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Convocazione rimossa.')));
        _reload();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppResult<_EventDetailData>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: AppLoadingView(message: 'Caricamento evento...'),
          );
        }

        final result = snapshot.data;

        if (result == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Evento')),
            body: AppErrorView(
              message: 'Risposta non valida durante il caricamento.',
              onRetry: _reload,
            ),
          );
        }

        switch (result) {
          case AppFailure(:final message):
            return Scaffold(
              appBar: AppBar(title: const Text('Evento')),
              body: AppErrorView(message: message, onRetry: _reload),
            );

          case AppSuccess(:final data):
            return Scaffold(
              appBar: AppBar(
                title: Text(data.event.title),
                actions: [
                  IconButton(
                    tooltip: 'Aggiungi convocati',
                    onPressed: () => _goToAddCallups(data.event),
                    icon: const Icon(Icons.group_add_outlined),
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
                    _EventInfoCard(event: data.event),
                    const SizedBox(height: 12),
                    _CallupsCard(
                      callups: data.callups,
                      onAddPressed: () => _goToAddCallups(data.event),
                      onRemovePressed: _removeCallup,
                    ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _goToAddCallups(data.event),
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Convoca'),
              ),
            );
        }
      },
    );
  }
}

class _EventDetailData {
  const _EventDetailData({required this.event, required this.callups});

  final EventSummary event;
  final List<CallupSummary> callups;
}

class _EventInfoCard extends StatelessWidget {
  const _EventInfoCard({required this.event});

  final EventSummary event;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              event.typeLabel,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF52616B)),
            ),
            const Divider(height: 28),
            _InfoRow(label: 'Inizio', value: _formatDateTime(event.startsAt)),
            _InfoRow(
              label: 'Fine',
              value: event.endsAt == null
                  ? 'Non indicata'
                  : _formatDateTime(event.endsAt!),
            ),
            _InfoRow(
              label: 'Squadra',
              value: event.teamName ?? 'Evento di club',
            ),
            _InfoRow(
              label: 'Luogo',
              value: event.locationName?.isNotEmpty == true
                  ? event.locationName!
                  : 'Non indicato',
            ),
            _InfoRow(
              label: 'RSVP',
              value: event.requireRsvp ? 'Richiesto' : 'Non richiesto',
            ),
            if (event.description != null &&
                event.description!.trim().isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                event.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString().padLeft(4, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}

class _CallupsCard extends StatelessWidget {
  const _CallupsCard({
    required this.callups,
    required this.onAddPressed,
    required this.onRemovePressed,
  });

  final List<CallupSummary> callups;
  final VoidCallback onAddPressed;
  final ValueChanged<CallupSummary> onRemovePressed;

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
                  Icons.group_add_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Convocazioni',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddPressed,
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (callups.isEmpty)
              AppEmptyState(
                icon: Icons.group_add_outlined,
                title: 'Nessun convocato',
                message: 'Aggiungi gli atleti da convocare per questo evento.',
                actionLabel: 'Aggiungi convocati',
                onActionPressed: onAddPressed,
              )
            else
              for (final callup in callups) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text(callup.athlete.initials)),
                  title: Text(callup.athlete.fullName),
                  subtitle: Text(
                    callup.athlete.teamName == null
                        ? callup.statusLabel
                        : '${callup.statusLabel} · ${callup.athlete.teamName}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Rimuovi',
                    onPressed: () => onRemovePressed(callup),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
                if (callup != callups.last) const Divider(),
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
            width: 110,
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
