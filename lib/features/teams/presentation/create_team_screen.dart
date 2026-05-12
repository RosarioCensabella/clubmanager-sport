import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../domain/create_team_request.dart';
import 'team_providers.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _sportController = TextEditingController();
  final _categoryController = TextEditingController();
  final _seasonController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _trainingLocationController = TextEditingController();
  final _colorController = TextEditingController();

  String _gender = 'unspecified';
  bool _isLoading = false;

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

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    final activeClubId = await ref
        .read(clubContextRepositoryProvider)
        .getActiveClubId();

    if (!mounted) {
      return;
    }

    if (activeClubId == null || activeClubId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona o crea un club prima di creare squadre.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final request = CreateTeamRequest(
      clubId: activeClubId,
      name: _nameController.text,
      sport: _sportController.text,
      category: _categoryController.text,
      season: _seasonController.text,
      birthYear: _parseBirthYear(),
      gender: _gender,
      trainingLocation: _trainingLocationController.text,
      color: _colorController.text,
    );

    final result = await ref.read(teamRepositoryProvider).createTeam(request);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Squadra creata correttamente.')),
        );
        context.pop();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  int? _parseBirthYear() {
    final text = _birthYearController.text.trim();

    if (text.isEmpty) {
      return null;
    }

    return int.tryParse(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crea squadra')),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Nuova squadra',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inserisci i dati principali della squadra. Allenatori e membri verranno collegati nelle fasi successive.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF52616B)),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome squadra',
                  hintText: 'Under 13, Prima Squadra...',
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
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Sport',
                  hintText: 'Calcio, Basket, Pallavolo...',
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
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  hintText: 'Esordienti, Under 15, Serie D...',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seasonController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Stagione',
                  hintText: '2026/2027',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthYearController,
                enabled: !_isLoading,
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
                  DropdownMenuItem(value: 'mixed', child: Text('Mista')),
                  DropdownMenuItem(value: 'male', child: Text('Maschile')),
                  DropdownMenuItem(value: 'female', child: Text('Femminile')),
                ],
                onChanged: _isLoading
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
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Luogo allenamenti',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _colorController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Colore squadra',
                  hintText: '#176B87 oppure Blu',
                  prefixIcon: Icon(Icons.palette_outlined),
                ),
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: 'Crea squadra',
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
