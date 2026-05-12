import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../domain/create_club_request.dart';
import 'club_context_providers.dart';

class CreateClubScreen extends ConsumerStatefulWidget {
  const CreateClubScreen({super.key});

  @override
  ConsumerState<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends ConsumerState<CreateClubScreen> {
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

  bool _isLoading = false;

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
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final request = CreateClubRequest(
      name: _nameController.text,
      sportPrimary: _sportController.text,
      city: _cityController.text,
      address: _addressController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      website: _websiteController.text,
      fiscalCode: _fiscalCodeController.text,
      season: _seasonController.text,
    );

    final result = await ref
        .read(clubContextRepositoryProvider)
        .createClub(request);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club creato correttamente.')),
        );
        context.go('/club-context');

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crea club')),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Crea il tuo club',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inserisci i dati principali della società sportiva. Potrai completarli più avanti.',
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
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Sport principale',
                  hintText: 'Calcio, Basket, Pallavolo...',
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
                enabled: !_isLoading,
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
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Stagione sportiva',
                  hintText: '2026/2027',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Dati opzionali',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Indirizzo sede',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                enabled: !_isLoading,
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
                enabled: !_isLoading,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteController,
                enabled: !_isLoading,
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
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Codice fiscale / P. IVA',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                ),
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: 'Crea club',
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
