import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../../teams/domain/team_summary.dart';
import '../../teams/presentation/team_providers.dart';
import '../domain/create_communication_request.dart';
import 'communication_providers.dart';

class CreateCommunicationScreen extends ConsumerStatefulWidget {
  const CreateCommunicationScreen({super.key});

  @override
  ConsumerState<CreateCommunicationScreen> createState() =>
      _CreateCommunicationScreenState();
}

class _CreateCommunicationScreenState
    extends ConsumerState<CreateCommunicationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String? _selectedTeamId;
  String _priority = 'normal';
  bool _allowComments = true;
  bool _sendPush = false;
  bool _isLoading = false;

  Future<List<TeamSummary>>? _teamsFuture;
  String? _activeClubId;

  @override
  void initState() {
    super.initState();
    _teamsFuture = _loadTeams();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
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
          content: Text('Seleziona o crea un club prima di comunicare.'),
        ),
      );
      return;
    }

    final userId = ref.read(communicationRepositoryProvider).currentUserId();

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devi effettuare l’accesso.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final request = CreateCommunicationRequest(
      clubId: clubId,
      teamId: _selectedTeamId,
      title: _titleController.text,
      body: _bodyController.text,
      priority: _priority,
      createdBy: userId,
      allowComments: _allowComments,
      sendPush: _sendPush,
    );

    final result = await ref
        .read(communicationRepositoryProvider)
        .createCommunication(request: request);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comunicazione pubblicata.')),
        );
        context.pop();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuova comunicazione')),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Comunicazione ufficiale',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pubblica un avviso per tutto il club o per una squadra specifica.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF52616B)),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Titolo',
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
              TextFormField(
                controller: _bodyController,
                enabled: !_isLoading,
                minLines: 6,
                maxLines: 10,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Messaggio',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                validator: (value) {
                  final body = value ?? '';

                  if (body.isBlank) {
                    return 'Inserisci il messaggio.';
                  }

                  if (body.trim().length < 10) {
                    return 'Il messaggio deve avere almeno 10 caratteri.';
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
                      labelText: 'Destinatari',
                      helperText:
                          'Se non selezioni una squadra, il messaggio sarà visibile a tutto il club.',
                      prefixIcon: Icon(Icons.groups_2_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tutto il club'),
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
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priorità',
                  prefixIcon: Icon(Icons.priority_high),
                ),
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Normale')),
                  DropdownMenuItem(
                    value: 'important',
                    child: Text('Importante'),
                  ),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _priority = value;
                          if (value == 'urgent') {
                            _sendPush = true;
                          }
                        });
                      },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _allowComments,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _allowComments = value;
                        });
                      },
                title: const Text('Permetti commenti'),
                subtitle: const Text(
                  'I commenti saranno completati in una fase successiva.',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _sendPush,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _sendPush = value;
                        });
                      },
                title: const Text('Notifica push'),
                subtitle: const Text(
                  'La spedizione effettiva sarà collegata nella Fase 21.',
                ),
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: 'Pubblica comunicazione',
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
