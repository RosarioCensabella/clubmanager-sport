import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../../teams/domain/team_summary.dart';
import '../../teams/presentation/team_providers.dart';
import '../domain/create_event_request.dart';
import 'event_providers.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startsAtController = TextEditingController();
  final _endsAtController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();

  String _type = 'training';
  String? _selectedTeamId;
  bool _requireRsvp = true;
  bool _isLoading = false;

  Future<List<TeamSummary>>? _teamsFuture;
  String? _activeClubId;

  @override
  void initState() {
    super.initState();
    _startsAtController.text = _defaultStartText();
    _teamsFuture = _loadTeams();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startsAtController.dispose();
    _endsAtController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<List<TeamSummary>> _loadTeams() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final teamRepository = ref.read(teamRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return [];
    }

    final result = await teamRepository.fetchTeamsForClub(
      clubId: _activeClubId!,
    );

    switch (result) {
      case AppSuccess(:final data):
        return data;
      case AppFailure():
        return [];
    }
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    final clubId =
        _activeClubId ??
        await ref.read(clubContextRepositoryProvider).getActiveClubId();

    if (!mounted) {
      return;
    }

    if (clubId == null || clubId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona o crea un club prima di creare eventi.'),
        ),
      );
      return;
    }

    final userId = ref.read(eventRepositoryProvider).currentUserId();

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devi effettuare l’accesso per creare eventi.'),
        ),
      );
      return;
    }

    final startsAt = _parseDateTime(_startsAtController.text);
    final endsAt = _parseDateTime(_endsAtController.text);

    if (startsAt == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Data inizio non valida.')));
      return;
    }

    if (endsAt != null && endsAt.isBefore(startsAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La data fine non può essere precedente all’inizio.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final visibility = _selectedTeamId == null ? 'club' : 'team';

    final request = CreateEventRequest(
      clubId: clubId,
      teamId: _selectedTeamId,
      type: _type,
      title: _titleController.text,
      description: _descriptionController.text,
      startsAt: startsAt,
      endsAt: endsAt,
      locationName: _locationController.text,
      address: _addressController.text,
      createdBy: userId,
      requireRsvp: _requireRsvp,
      visibility: visibility,
    );

    final result = await ref
        .read(eventRepositoryProvider)
        .createEvent(request: request);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento creato correttamente.')),
        );
        context.pop();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  DateTime? _parseDateTime(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    final normalized = trimmed.replaceFirst(' ', 'T');

    return DateTime.tryParse(normalized);
  }

  String? _validateRequiredDateTime(String? value) {
    final text = value ?? '';

    if (text.isBlank) {
      return 'Inserisci data e ora.';
    }

    if (_parseDateTime(text) == null) {
      return 'Usa il formato AAAA-MM-GG HH:MM.';
    }

    return null;
  }

  String? _validateOptionalDateTime(String? value) {
    final text = value ?? '';

    if (text.isBlank) {
      return null;
    }

    if (_parseDateTime(text) == null) {
      return 'Usa il formato AAAA-MM-GG HH:MM.';
    }

    return null;
  }

  String _defaultStartText() {
    final now = DateTime.now().add(const Duration(days: 1));
    final rounded = DateTime(now.year, now.month, now.day, 18);

    final year = rounded.year.toString().padLeft(4, '0');
    final month = rounded.month.toString().padLeft(2, '0');
    final day = rounded.day.toString().padLeft(2, '0');
    final hour = rounded.hour.toString().padLeft(2, '0');
    final minute = rounded.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo evento')),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Crea evento',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea allenamenti, partite, riunioni o altre scadenze. Convocazioni e presenze saranno gestite nelle prossime fasi.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF52616B)),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo evento',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'training',
                    child: Text('Allenamento'),
                  ),
                  DropdownMenuItem(value: 'match', child: Text('Partita')),
                  DropdownMenuItem(value: 'tournament', child: Text('Torneo')),
                  DropdownMenuItem(value: 'meeting', child: Text('Riunione')),
                  DropdownMenuItem(
                    value: 'medical_visit',
                    child: Text('Visita medica'),
                  ),
                  DropdownMenuItem(
                    value: 'social_event',
                    child: Text('Evento sociale'),
                  ),
                  DropdownMenuItem(
                    value: 'payment_deadline',
                    child: Text('Scadenza pagamento'),
                  ),
                  DropdownMenuItem(value: 'other', child: Text('Altro')),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _type = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Titolo',
                  hintText: 'Allenamento Under 13',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                validator: (value) {
                  final title = value ?? '';

                  if (title.isBlank) {
                    return 'Inserisci il titolo.';
                  }

                  if (title.trim().length < 3) {
                    return 'Il titolo deve avere almeno 3 caratteri.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<TeamSummary>>(
                future: _teamsFuture,
                builder: (context, snapshot) {
                  final teams = snapshot.data ?? [];

                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedTeamId,
                    decoration: const InputDecoration(
                      labelText: 'Squadra',
                      helperText:
                          'Se non selezioni una squadra, l’evento sarà di club.',
                      prefixIcon: Icon(Icons.groups_2_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Evento di club'),
                      ),
                      for (final team in teams)
                        DropdownMenuItem<String?>(
                          value: team.id,
                          child: Text(team.name),
                        ),
                    ],
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _selectedTeamId = value;
                            });
                          },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _startsAtController,
                enabled: !_isLoading,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Inizio',
                  hintText: 'AAAA-MM-GG HH:MM',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                validator: _validateRequiredDateTime,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _endsAtController,
                enabled: !_isLoading,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Fine',
                  hintText: 'AAAA-MM-GG HH:MM',
                  prefixIcon: Icon(Icons.event_available_outlined),
                ),
                validator: _validateOptionalDateTime,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Luogo',
                  hintText: 'Campo comunale',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Indirizzo',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: !_isLoading,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descrizione',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _requireRsvp,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _requireRsvp = value;
                        });
                      },
                title: const Text('Richiedi conferma presenza'),
                subtitle: const Text(
                  'RSVP e convocazioni saranno completati nelle prossime fasi.',
                ),
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: 'Crea evento',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
