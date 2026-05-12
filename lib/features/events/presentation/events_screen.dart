import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../domain/event_summary.dart';
import 'event_providers.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  late Future<AppResult<List<EventSummary>>> _future;

  String? _activeClubId;

  @override
  void initState() {
    super.initState();
    _future = _loadEvents();
  }

  Future<AppResult<List<EventSummary>>> _loadEvents() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final eventRepository = ref.read(eventRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return const AppFailure(
        'Seleziona o crea un club prima di gestire il calendario.',
        code: 'active_club_missing',
      );
    }

    return eventRepository.fetchEventsForClub(clubId: _activeClubId!);
  }

  void _reload() {
    setState(() {
      _future = _loadEvents();
    });
  }

  void _goToCreateEvent() {
    context.push('/events/create').then((_) => _reload());
  }

  void _goToEventDetail(EventSummary event) {
    context.push('/events/${event.id}').then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [
          IconButton(
            tooltip: 'Nuovo evento',
            onPressed: _goToCreateEvent,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<AppResult<List<EventSummary>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(message: 'Caricamento calendario...');
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
                  icon: Icons.event_outlined,
                  title: 'Nessun evento',
                  message:
                      'Crea allenamenti, partite, riunioni o altre scadenze del club.',
                  actionLabel: 'Crea evento',
                  onActionPressed: _goToCreateEvent,
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _reload();
                  await _future;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: data.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final event = data[index];

                    return _EventCard(
                      event: event,
                      onTap: () => _goToEventDetail(event),
                    );
                  },
                ),
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreateEvent,
        icon: const Icon(Icons.add),
        label: const Text('Nuovo evento'),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});

  final EventSummary event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.event_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildSubtitle(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF52616B),
                      ),
                    ),
                    if (event.description != null &&
                        event.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        event.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(event.typeLabel),
                          avatar: const Icon(Icons.category_outlined, size: 18),
                        ),
                        Chip(
                          label: Text(event.statusLabel),
                          avatar: Icon(
                            Icons.circle,
                            color: statusColor,
                            size: 14,
                          ),
                        ),
                        Chip(
                          label: Text(event.visibilityLabel),
                          avatar: const Icon(
                            Icons.visibility_outlined,
                            size: 18,
                          ),
                        ),
                        if (event.requireRsvp)
                          const Chip(
                            label: Text('RSVP richiesto'),
                            avatar: Icon(Icons.how_to_reg_outlined, size: 18),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[_formatDateTime(event.startsAt)];

    if (event.endsAt != null) {
      parts.add('fine ${_formatDateTime(event.endsAt!)}');
    }

    if (event.teamName != null && event.teamName!.isNotEmpty) {
      parts.add(event.teamName!);
    }

    if (event.locationName != null && event.locationName!.isNotEmpty) {
      parts.add(event.locationName!);
    }

    return parts.join(' · ');
  }

  Color _statusColor() {
    switch (event.status) {
      case 'scheduled':
        return const Color(0xFF176B87);
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString().padLeft(4, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
