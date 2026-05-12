import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../athletes/domain/athlete_summary.dart';
import '../../athletes/presentation/athlete_providers.dart';
import '../../events/domain/event_summary.dart';
import '../../events/presentation/event_providers.dart';
import 'callup_providers.dart';

class AddCallupsScreen extends ConsumerStatefulWidget {
  const AddCallupsScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<AddCallupsScreen> createState() => _AddCallupsScreenState();
}

class _AddCallupsScreenState extends ConsumerState<AddCallupsScreen> {
  final _notesController = TextEditingController();

  late Future<AppResult<_AddCallupsData>> _future;

  final Set<String> _selectedAthleteIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<AppResult<_AddCallupsData>> _loadData() async {
    final eventRepository = ref.read(eventRepositoryProvider);
    final athleteRepository = ref.read(athleteRepositoryProvider);
    final callupRepository = ref.read(callupRepositoryProvider);

    final eventResult = await eventRepository.fetchEventById(
      eventId: widget.eventId,
    );

    switch (eventResult) {
      case AppFailure(:final message, :final code):
        return AppFailure(message, code: code);

      case AppSuccess(:final data):
        final event = data;

        final athletesResult = await athleteRepository.fetchAthletesForClub(
          clubId: event.clubId,
        );

        switch (athletesResult) {
          case AppFailure(:final message, :final code):
            return AppFailure(message, code: code);

          case AppSuccess(:final data):
            final athletes = data;
            final callupsResult = await callupRepository.fetchCallupsForEvent(
              eventId: event.id,
            );

            switch (callupsResult) {
              case AppFailure(:final message, :final code):
                return AppFailure(message, code: code);

              case AppSuccess(:final data):
                final alreadyCalledIds = data
                    .map((callup) => callup.athleteProfileId)
                    .toSet();

                final availableAthletes = athletes
                    .where((athlete) {
                      final notAlreadyCalled = !alreadyCalledIds.contains(
                        athlete.id,
                      );

                      if (!notAlreadyCalled) {
                        return false;
                      }

                      if (event.teamId == null || event.teamId!.isEmpty) {
                        return true;
                      }

                      return athlete.teamId == event.teamId;
                    })
                    .toList(growable: false);

                return AppSuccess(
                  _AddCallupsData(
                    event: event,
                    availableAthletes: availableAthletes,
                  ),
                );
            }
        }
    }
  }

  void _reload() {
    setState(() {
      _selectedAthleteIds.clear();
      _future = _loadData();
    });
  }

  void _toggleAthlete(String athleteId, bool selected) {
    setState(() {
      if (selected) {
        _selectedAthleteIds.add(athleteId);
      } else {
        _selectedAthleteIds.remove(athleteId);
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedAthleteIds.isEmpty || _isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno un atleta.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ref
        .read(callupRepositoryProvider)
        .createCallups(
          eventId: widget.eventId,
          athleteProfileIds: _selectedAthleteIds.toList(growable: false),
          notes: _notesController.text,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AppSuccess(:final data):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Convocazioni create: $data.')));
        context.pop();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppResult<_AddCallupsData>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: AppLoadingView(message: 'Caricamento atleti disponibili...'),
          );
        }

        final result = snapshot.data;

        if (result == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Aggiungi convocati')),
            body: AppErrorView(
              message: 'Risposta non valida durante il caricamento.',
              onRetry: _reload,
            ),
          );
        }

        switch (result) {
          case AppFailure(:final message):
            return Scaffold(
              appBar: AppBar(title: const Text('Aggiungi convocati')),
              body: AppErrorView(message: message, onRetry: _reload),
            );

          case AppSuccess(:final data):
            return Scaffold(
              appBar: AppBar(title: const Text('Aggiungi convocati')),
              body: SafeArea(
                minimum: const EdgeInsets.all(24),
                child: ListView(
                  children: [
                    Text(
                      data.event.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.event.teamName == null
                          ? 'Evento di club: puoi convocare qualsiasi atleta del club.'
                          : 'Evento squadra: vengono mostrati solo gli atleti della squadra ${data.event.teamName}.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF52616B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _notesController,
                      enabled: !_isLoading,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Note convocazione',
                        hintText: 'Opzionale',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Atleti disponibili',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (data.availableAthletes.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Text(
                            'Non ci sono atleti disponibili da convocare. Potrebbero essere già tutti convocati oppure non esserci atleti nella squadra selezionata.',
                          ),
                        ),
                      )
                    else
                      for (final athlete in data.availableAthletes)
                        Card(
                          child: CheckboxListTile(
                            value: _selectedAthleteIds.contains(athlete.id),
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    _toggleAthlete(athlete.id, value ?? false);
                                  },
                            title: Text(athlete.fullName),
                            subtitle: Text(
                              athlete.teamName ?? 'Nessuna squadra',
                            ),
                            secondary: CircleAvatar(
                              child: Text(athlete.initials),
                            ),
                          ),
                        ),
                    const SizedBox(height: 28),
                    AppPrimaryButton(
                      label: 'Crea convocazioni',
                      isLoading: _isLoading,
                      onPressed: data.availableAthletes.isEmpty
                          ? null
                          : _submit,
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

class _AddCallupsData {
  const _AddCallupsData({required this.event, required this.availableAthletes});

  final EventSummary event;
  final List<AthleteSummary> availableAthletes;
}
