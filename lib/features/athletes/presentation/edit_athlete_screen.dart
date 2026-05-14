import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../teams/domain/team_summary.dart';
import '../../teams/presentation/team_providers.dart';
import '../domain/athlete_summary.dart';
import '../domain/update_athlete_request.dart';
import 'athlete_providers.dart';

class EditAthleteScreen extends ConsumerStatefulWidget {
  const EditAthleteScreen({super.key, required this.athleteId});

  final String athleteId;

  @override
  ConsumerState<EditAthleteScreen> createState() => _EditAthleteScreenState();
}

class _EditAthleteScreenState extends ConsumerState<EditAthleteScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _jerseyNumberController = TextEditingController();
  final _sportRoleController = TextEditingController();
  final _medicalExpiryController = TextEditingController();
  final _staffNotesController = TextEditingController();

  late Future<AppResult<_EditAthleteData>> _future;

  String? _selectedTeamId;
  String _medicalStatus = 'missing';
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
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

  Future<AppResult<_EditAthleteData>> _load() async {
    final athleteResult = await ref
        .read(athleteRepositoryProvider)
        .fetchAthleteById(athleteId: widget.athleteId);

    switch (athleteResult) {
      case AppFailure(:final message, :final code):
        return AppFailure(message, code: code);

      case AppSuccess(data: final athlete):
        final teamsResult = await ref
            .read(teamRepositoryProvider)
            .fetchTeamsForClub(clubId: athlete.clubId);

        switch (teamsResult) {
          case AppFailure():
            return AppSuccess(
              _EditAthleteData(athlete: athlete, teams: const []),
            );

          case AppSuccess(data: final teams):
            return AppSuccess(_EditAthleteData(athlete: athlete, teams: teams));
        }
    }
  }

  void _fillForm(_EditAthleteData data) {
    if (_initialized) {
      return;
    }

    final athlete = data.athlete;

    _firstNameController.text = athlete.firstName;
    _lastNameController.text = athlete.lastName;
    _dateOfBirthController.text = _dateToInput(athlete.dateOfBirth);
    _jerseyNumberController.text = athlete.jerseyNumber ?? '';
    _sportRoleController.text = athlete.sportRole ?? '';
    _medicalExpiryController.text = _dateToInput(
      athlete.medicalCertificateExpiry,
    );
    _staffNotesController.text = athlete.staffNotes ?? '';
    _selectedTeamId = athlete.teamId;
    _medicalStatus = athlete.medicalCertificateStatus;

    _initialized = true;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final request = UpdateAthleteRequest(
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
        .updateAthlete(athleteId: widget.athleteId, request: request);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Atleta aggiornato correttamente.')),
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

  String _dateToInput(DateTime? value) {
    if (value == null) {
      return '';
    }

    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
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
    return FutureBuilder<AppResult<_EditAthleteData>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: AppLoadingView(message: 'Caricamento atleta...'),
          );
        }

        final result = snapshot.data;

        if (result == null) {
          return const Scaffold(
            body: AppErrorView(
              message: 'Risposta non valida durante il caricamento.',
            ),
          );
        }

        switch (result) {
          case AppFailure(:final message):
            return Scaffold(
              appBar: AppBar(title: const Text('Modifica atleta')),
              body: AppErrorView(message: message),
            );

          case AppSuccess(data: final data):
            _fillForm(data);

            return Scaffold(
              appBar: AppBar(title: const Text('Modifica atleta')),
              body: SafeArea(
                minimum: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Text(
                        'Dati atleta',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aggiorna anagrafica, squadra e informazioni operative.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF52616B),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _firstNameController,
                        enabled: !_isSaving,
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
                        enabled: !_isSaving,
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
                      DropdownButtonFormField<String?>(
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
                          for (final team in data.teams)
                            DropdownMenuItem<String?>(
                              value: team.id,
                              child: Text(team.name),
                            ),
                        ],
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedTeamId = value;
                                });
                              },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dateOfBirthController,
                        enabled: !_isSaving,
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
                        enabled: !_isSaving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Numero maglia',
                          prefixIcon: Icon(Icons.numbers_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sportRoleController,
                        enabled: !_isSaving,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Ruolo sportivo',
                          prefixIcon: Icon(Icons.sports_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Certificato medico',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _medicalStatus,
                        decoration: const InputDecoration(
                          labelText: 'Stato certificato',
                          prefixIcon: Icon(Icons.medical_information_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'missing',
                            child: Text('Mancante'),
                          ),
                          DropdownMenuItem(
                            value: 'pending_review',
                            child: Text('In verifica'),
                          ),
                          DropdownMenuItem(
                            value: 'valid',
                            child: Text('Valido'),
                          ),
                          DropdownMenuItem(
                            value: 'expiring',
                            child: Text('In scadenza'),
                          ),
                          DropdownMenuItem(
                            value: 'expired',
                            child: Text('Scaduto'),
                          ),
                          DropdownMenuItem(
                            value: 'rejected',
                            child: Text('Rifiutato'),
                          ),
                        ],
                        onChanged: _isSaving
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
                        enabled: !_isSaving,
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
                        enabled: !_isSaving,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Note staff private',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppPrimaryButton(
                        label: 'Salva modifiche',
                        isLoading: _isSaving,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}

class _EditAthleteData {
  const _EditAthleteData({required this.athlete, required this.teams});

  final AthleteSummary athlete;
  final List<TeamSummary> teams;
}
