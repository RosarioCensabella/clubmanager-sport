import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../athletes/domain/athlete_summary.dart';
import '../../athletes/presentation/athlete_providers.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../../teams/domain/team_summary.dart';
import '../../teams/presentation/team_providers.dart';
import '../domain/create_fee_request.dart';
import 'fee_providers.dart';

class CreateFeeScreen extends ConsumerStatefulWidget {
  const CreateFeeScreen({super.key});

  @override
  ConsumerState<CreateFeeScreen> createState() => _CreateFeeScreenState();
}

class _CreateFeeScreenState extends ConsumerState<CreateFeeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _dueDateController = TextEditingController();

  String _scope = 'club';
  String? _selectedTeamId;
  final Set<String> _selectedAthleteIds = {};

  bool _isLoading = false;

  Future<_FeeTargetsData>? _targetsFuture;
  String? _activeClubId;

  @override
  void initState() {
    super.initState();
    _targetsFuture = _loadTargets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<_FeeTargetsData> _loadTargets() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final teamRepository = ref.read(teamRepositoryProvider);
    final athleteRepository = ref.read(athleteRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return const _FeeTargetsData(teams: [], athletes: []);
    }

    final teamsResult = await teamRepository.fetchTeamsForClub(
      clubId: _activeClubId!,
    );

    final athletesResult = await athleteRepository.fetchAthletesForClub(
      clubId: _activeClubId!,
    );

    final teams = switch (teamsResult) {
      AppSuccess(:final data) => data,
      AppFailure() => <TeamSummary>[],
    };

    final athletes = switch (athletesResult) {
      AppSuccess(:final data) => data,
      AppFailure() => <AthleteSummary>[],
    };

    return _FeeTargetsData(teams: teams, athletes: athletes);
  }

  Future<void> _submit(_FeeTargetsData targets) async {
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
        const SnackBar(content: Text('Seleziona o crea un club.')),
      );
      return;
    }

    final userId = ref.read(feeRepositoryProvider).currentUserId();

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devi effettuare l’accesso.')),
      );
      return;
    }

    final selectedAthletes = _resolveAthleteIds(targets);

    if (selectedAthletes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno un atleta.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final request = CreateFeeRequest(
      clubId: clubId,
      title: _titleController.text,
      description: _descriptionController.text,
      amountCents: _parseAmountCents(_amountController.text),
      currency: 'EUR',
      scope: _scope,
      teamId: _scope == 'team' ? _selectedTeamId : null,
      athleteProfileIds: selectedAthletes,
      dueDate: _parseDate(_dueDateController.text),
      createdBy: userId,
    );

    final result = await ref
        .read(feeRepositoryProvider)
        .createFeeWithAssignments(request: request);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quota creata correttamente.')),
        );
        context.pop();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  List<String> _resolveAthleteIds(_FeeTargetsData targets) {
    switch (_scope) {
      case 'club':
        return targets.athletes.map((athlete) => athlete.id).toList();

      case 'team':
        return targets.athletes
            .where((athlete) => athlete.teamId == _selectedTeamId)
            .map((athlete) => athlete.id)
            .toList();

      case 'athlete':
        return _selectedAthleteIds.toList(growable: false);

      default:
        return [];
    }
  }

  int _parseAmountCents(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    final amount = double.tryParse(normalized) ?? 0;

    return (amount * 100).round();
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return DateTime.tryParse(trimmed);
  }

  String? _validateAmount(String? value) {
    final text = value ?? '';

    if (text.isBlank) {
      return 'Inserisci l’importo.';
    }

    final amount = double.tryParse(text.trim().replaceAll(',', '.'));

    if (amount == null || amount <= 0) {
      return 'Inserisci un importo valido.';
    }

    return null;
  }

  String? _validateOptionalDate(String? value) {
    final text = value ?? '';

    if (text.isBlank) {
      return null;
    }

    if (DateTime.tryParse(text.trim()) == null) {
      return 'Usa il formato AAAA-MM-GG.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuova quota')),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: FutureBuilder<_FeeTargetsData>(
          future: _targetsFuture,
          builder: (context, snapshot) {
            final targets =
                snapshot.data ?? const _FeeTargetsData(teams: [], athletes: []);

            return Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text(
                    'Crea quota associativa',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea una quota e assegnala agli atleti del club.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF52616B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titleController,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Titolo quota',
                      prefixIcon: Icon(Icons.title_outlined),
                    ),
                    validator: (value) {
                      final title = value ?? '';

                      if (title.isBlank) {
                        return 'Inserisci il titolo.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !_isLoading,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Descrizione',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    enabled: !_isLoading,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Importo',
                      hintText: 'Es. 120,00',
                      prefixIcon: Icon(Icons.euro_outlined),
                    ),
                    validator: _validateAmount,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dueDateController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Scadenza',
                      hintText: 'AAAA-MM-GG',
                      prefixIcon: Icon(Icons.event_available_outlined),
                    ),
                    validator: _validateOptionalDate,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _scope,
                    decoration: const InputDecoration(
                      labelText: 'Destinatari',
                      prefixIcon: Icon(Icons.groups_2_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'club',
                        child: Text('Tutti gli atleti del club'),
                      ),
                      DropdownMenuItem(
                        value: 'team',
                        child: Text('Una squadra'),
                      ),
                      DropdownMenuItem(
                        value: 'athlete',
                        child: Text('Atleti selezionati'),
                      ),
                    ],
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _scope = value;
                              _selectedTeamId = null;
                              _selectedAthleteIds.clear();
                            });
                          },
                  ),
                  if (_scope == 'team') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTeamId,
                      decoration: const InputDecoration(
                        labelText: 'Squadra',
                        prefixIcon: Icon(Icons.groups_2_outlined),
                      ),
                      items: [
                        for (final team in targets.teams)
                          DropdownMenuItem(
                            value: team.id,
                            child: Text(team.name),
                          ),
                      ],
                      validator: (value) {
                        if (_scope == 'team' &&
                            (value == null || value.isEmpty)) {
                          return 'Seleziona una squadra.';
                        }

                        return null;
                      },
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _selectedTeamId = value;
                              });
                            },
                    ),
                  ],
                  if (_scope == 'athlete') ...[
                    const SizedBox(height: 16),
                    Text(
                      'Seleziona atleti',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final athlete in targets.athletes)
                      CheckboxListTile(
                        value: _selectedAthleteIds.contains(athlete.id),
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedAthleteIds.add(athlete.id);
                                  } else {
                                    _selectedAthleteIds.remove(athlete.id);
                                  }
                                });
                              },
                        title: Text(athlete.fullName),
                        subtitle: Text(athlete.teamName ?? 'Nessuna squadra'),
                      ),
                  ],
                  const SizedBox(height: 28),
                  AppPrimaryButton(
                    label: 'Crea quota',
                    isLoading: _isLoading,
                    onPressed: () => _submit(targets),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeeTargetsData {
  const _FeeTargetsData({required this.teams, required this.athletes});

  final List<TeamSummary> teams;
  final List<AthleteSummary> athletes;
}
