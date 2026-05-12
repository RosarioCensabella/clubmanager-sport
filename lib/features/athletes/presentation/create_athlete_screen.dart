import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../../teams/domain/team_summary.dart';
import '../../teams/presentation/team_providers.dart';
import '../domain/create_athlete_request.dart';
import 'athlete_providers.dart';

class CreateAthleteScreen extends ConsumerStatefulWidget {
  const CreateAthleteScreen({super.key});

  @override
  ConsumerState<CreateAthleteScreen> createState() =>
      _CreateAthleteScreenState();
}

class _CreateAthleteScreenState extends ConsumerState<CreateAthleteScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _jerseyNumberController = TextEditingController();
  final _sportRoleController = TextEditingController();
  final _medicalExpiryController = TextEditingController();
  final _staffNotesController = TextEditingController();

  String? _selectedTeamId;
  String _medicalStatus = 'missing';
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _jerseyNumberController.dispose();
    _sportRoleController.dispose();
    _medicalExpiryController.dispose();
    _staffNotesController.dispose();
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
          content: Text('Seleziona o crea un club prima di creare atleti.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final request = CreateAthleteRequest(
      clubId: clubId,
      teamId: _selectedTeamId,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      dateOfBirth: _parseDate(_dateOfBirthController.text),
      jerseyNumber: _jerseyNumberController.text,
      sportRole: _sportRoleController.text,
      medicalCertificateStatus: _medicalStatus,
      medicalCertificateExpiry: _parseDate(_medicalExpiryController.text),
      staffNotes: _staffNotesController.text,
    );

    final result = await ref
        .read(athleteRepositoryProvider)
        .createAthlete(request);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Atleta creato correttamente.')),
        );
        context.pop();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return DateTime.tryParse(trimmed);
  }

  String? _validateOptionalDate(String? value) {
    final text = value ?? '';

    if (text.isBlank) {
      return null;
    }

    final parsed = DateTime.tryParse(text.trim());

    if (parsed == null) {
      return 'Usa il formato AAAA-MM-GG.';
    }

    return null;
  }

  String? _validateBirthDate(String? value) {
    final validation = _validateOptionalDate(value);

    if (validation != null) {
      return validation;
    }

    final text = value ?? '';

    if (text.isBlank) {
      return null;
    }

    final parsed = DateTime.tryParse(text.trim());

    if (parsed != null && parsed.isAfter(DateTime.now())) {
      return 'La data di nascita non può essere futura.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo atleta')),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Aggiungi atleta',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inserisci i dati principali. I dati sanitari sono minimizzati a stato e scadenza certificato.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF52616B)),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _firstNameController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  final firstName = value ?? '';

                  if (firstName.isBlank) {
                    return 'Inserisci il nome.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Cognome',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  final lastName = value ?? '';

                  if (lastName.isBlank) {
                    return 'Inserisci il cognome.';
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
                      helperText: 'Opzionale.',
                      prefixIcon: Icon(Icons.groups_2_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Nessuna squadra'),
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
                controller: _dateOfBirthController,
                enabled: !_isLoading,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Data di nascita',
                  hintText: 'AAAA-MM-GG',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                validator: _validateBirthDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jerseyNumberController,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Numero maglia',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sportRoleController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Ruolo sportivo',
                  hintText: 'Portiere, Ala, Centrale...',
                  prefixIcon: Icon(Icons.sports_outlined),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Certificato medico',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _medicalStatus,
                decoration: const InputDecoration(
                  labelText: 'Stato certificato',
                  prefixIcon: Icon(Icons.medical_information_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'missing', child: Text('Mancante')),
                  DropdownMenuItem(
                    value: 'pending_review',
                    child: Text('In verifica'),
                  ),
                  DropdownMenuItem(value: 'valid', child: Text('Valido')),
                  DropdownMenuItem(
                    value: 'expiring',
                    child: Text('In scadenza'),
                  ),
                  DropdownMenuItem(value: 'expired', child: Text('Scaduto')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rifiutato')),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _medicalStatus = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _medicalExpiryController,
                enabled: !_isLoading,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Scadenza certificato',
                  hintText: 'AAAA-MM-GG',
                  prefixIcon: Icon(Icons.event_available_outlined),
                ),
                validator: _validateOptionalDate,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _staffNotesController,
                enabled: !_isLoading,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Note staff private',
                  helperText:
                      'Non mostrare queste note a genitori o atleti nelle schermate pubbliche.',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: 'Crea atleta',
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
