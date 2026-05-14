import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../domain/team_detail.dart';
import '../domain/update_team_request.dart';
import 'team_providers.dart';

class EditTeamScreen extends ConsumerStatefulWidget {
  const EditTeamScreen({super.key, required this.teamId});

  final String teamId;

  @override
  ConsumerState<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends ConsumerState<EditTeamScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _sportController = TextEditingController();
  final _categoryController = TextEditingController();
  final _seasonController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _trainingLocationController = TextEditingController();
  final _colorController = TextEditingController();

  late Future<AppResult<TeamDetail>> _future;

  String _gender = 'unspecified';
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sportController.dispose();
    _categoryController.dispose();
    _seasonController.dispose();
    _birthYearController.dispose();
    _trainingLocationController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<AppResult<TeamDetail>> _load() {
    return ref
        .read(teamRepositoryProvider)
        .fetchTeamById(teamId: widget.teamId);
  }

  void _fillForm(TeamDetail team) {
    if (_initialized) {
      return;
    }

    _nameController.text = team.name;
    _sportController.text = team.sport;
    _categoryController.text = team.category ?? '';
    _seasonController.text = team.season ?? '';
    _birthYearController.text = team.birthYear?.toString() ?? '';
    _trainingLocationController.text = team.trainingLocation ?? '';
    _colorController.text = team.color ?? '';
    _gender = team.gender;

    _initialized = true;
  }

  int? _parseBirthYear() {
    final text = _birthYearController.text.trim();

    if (text.isEmpty) {
      return null;
    }

    return int.tryParse(text);
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final request = UpdateTeamRequest(
      name: _nameController.text,
      sport: _sportController.text,
      category: _categoryController.text,
      season: _seasonController.text,
      birthYear: _parseBirthYear(),
      gender: _gender,
      trainingLocation: _trainingLocationController.text,
      color: _colorController.text,
    );

    final result = await ref
        .read(teamRepositoryProvider)
        .updateTeam(teamId: widget.teamId, request: request);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Squadra aggiornata correttamente.')),
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
    return FutureBuilder<AppResult<TeamDetail>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: AppLoadingView(message: 'Caricamento squadra...'),
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
              appBar: AppBar(title: const Text('Modifica squadra')),
              body: AppErrorView(message: message),
            );

          case AppSuccess(:final data):
            _fillForm(data);

            return Scaffold(
              appBar: AppBar(title: const Text('Modifica squadra')),
              body: SafeArea(
                minimum: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Text(
                        'Dati squadra',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aggiorna le informazioni principali della squadra.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF52616B),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        enabled: !_isSaving,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nome squadra',
                          prefixIcon: Icon(Icons.groups_2_outlined),
                        ),
                        validator: (value) {
                          final name = value ?? '';

                          if (name.isBlank) {
                            return 'Inserisci il nome della squadra.';
                          }

                          if (name.trim().length < 2) {
                            return 'Il nome deve avere almeno 2 caratteri.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sportController,
                        enabled: !_isSaving,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Sport',
                          prefixIcon: Icon(Icons.sports_soccer_outlined),
                        ),
                        validator: (value) {
                          final sport = value ?? '';

                          if (sport.isBlank) {
                            return 'Inserisci lo sport.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _categoryController,
                        enabled: !_isSaving,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _seasonController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Stagione',
                          hintText: '2026/2027',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _birthYearController,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Anno di nascita',
                          hintText: '2014',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                        validator: (value) {
                          final text = value ?? '';

                          if (text.isBlank) {
                            return null;
                          }

                          final year = int.tryParse(text);

                          if (year == null) {
                            return 'Inserisci un anno valido.';
                          }

                          if (year < 1900 || year > 2100) {
                            return 'Inserisci un anno realistico.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Genere',
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'unspecified',
                            child: Text('Non specificato'),
                          ),
                          DropdownMenuItem(
                            value: 'mixed',
                            child: Text('Mista'),
                          ),
                          DropdownMenuItem(
                            value: 'male',
                            child: Text('Maschile'),
                          ),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Femminile'),
                          ),
                        ],
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  _gender = value;
                                });
                              },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _trainingLocationController,
                        enabled: !_isSaving,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Luogo allenamenti',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _colorController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Colore squadra',
                          hintText: '#176B87 oppure Blu',
                          prefixIcon: Icon(Icons.palette_outlined),
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
