import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../domain/club_management_data.dart';
import '../domain/update_club_request.dart';
import 'club_context_providers.dart';

class EditClubScreen extends ConsumerStatefulWidget {
  const EditClubScreen({super.key, required this.clubId});

  final String clubId;

  @override
  ConsumerState<EditClubScreen> createState() => _EditClubScreenState();
}

class _EditClubScreenState extends ConsumerState<EditClubScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _sportController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _fiscalCodeController = TextEditingController();
  final _seasonController = TextEditingController();
  final _primaryColorController = TextEditingController();

  late Future<AppResult<ClubManagementData>> _future;

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
    _cityController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _fiscalCodeController.dispose();
    _seasonController.dispose();
    _primaryColorController.dispose();
    super.dispose();
  }

  Future<AppResult<ClubManagementData>> _load() {
    return ref
        .read(clubContextRepositoryProvider)
        .fetchClubManagementData(clubId: widget.clubId);
  }

  void _fillForm(ClubManagementData data) {
    if (_initialized) {
      return;
    }

    final club = data.club;

    _nameController.text = club.name;
    _sportController.text = club.sportPrimary;
    _cityController.text = club.city;
    _addressController.text = club.address ?? '';
    _emailController.text = club.email ?? '';
    _phoneController.text = club.phone ?? '';
    _websiteController.text = club.website ?? '';
    _fiscalCodeController.text = club.fiscalCode ?? '';
    _seasonController.text = club.season ?? '';
    _primaryColorController.text = club.primaryColor ?? '';

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

    final request = UpdateClubRequest(
      name: _nameController.text,
      sportPrimary: _sportController.text,
      city: _cityController.text,
      address: _addressController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      website: _websiteController.text,
      fiscalCode: _fiscalCodeController.text,
      season: _seasonController.text,
      primaryColor: _primaryColorController.text,
    );

    final result = await ref
        .read(clubContextRepositoryProvider)
        .updateClub(clubId: widget.clubId, request: request);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club aggiornato correttamente.')),
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
    return FutureBuilder<AppResult<ClubManagementData>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: AppLoadingView(message: 'Caricamento dati club...'),
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
              appBar: AppBar(title: const Text('Modifica club')),
              body: AppErrorView(message: message),
            );

          case AppSuccess(:final data):
            _fillForm(data);

            if (!data.canManageClub) {
              return Scaffold(
                appBar: AppBar(title: const Text('Modifica club')),
                body: const SafeArea(
                  minimum: EdgeInsets.all(24),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'Solo proprietari e amministratori possono modificare il club.',
                      ),
                    ),
                  ),
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(title: const Text('Modifica club')),
              body: SafeArea(
                minimum: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Text(
                        'Dati club',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aggiorna le informazioni principali del club.',
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
                          labelText: 'Nome club',
                          prefixIcon: Icon(Icons.shield_outlined),
                        ),
                        validator: (value) {
                          final name = value ?? '';

                          if (name.isBlank) {
                            return 'Inserisci il nome del club.';
                          }

                          if (name.trim().length < 3) {
                            return 'Il nome deve avere almeno 3 caratteri.';
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
                          labelText: 'Sport principale',
                          prefixIcon: Icon(Icons.sports_soccer_outlined),
                        ),
                        validator: (value) {
                          final sport = value ?? '';

                          if (sport.isBlank) {
                            return 'Inserisci lo sport principale.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cityController,
                        enabled: !_isSaving,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Città',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                        validator: (value) {
                          final city = value ?? '';

                          if (city.isBlank) {
                            return 'Inserisci la città.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _seasonController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Stagione sportiva',
                          hintText: '2026/2027',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Dati opzionali',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        enabled: !_isSaving,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Indirizzo sede',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email ufficiale',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final email = value ?? '';

                          if (email.isBlank) {
                            return null;
                          }

                          if (!email.isValidEmail) {
                            return 'Inserisci un indirizzo email valido.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefono',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _websiteController,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Sito web',
                          hintText: 'https://www.esempio.it',
                          prefixIcon: Icon(Icons.language_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fiscalCodeController,
                        enabled: !_isSaving,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Codice fiscale / P. IVA',
                          prefixIcon: Icon(Icons.receipt_long_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _primaryColorController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Colore primario',
                          hintText: '#0B63CE',
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
