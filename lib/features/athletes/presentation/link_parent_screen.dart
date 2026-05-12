import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_primary_button.dart';
import 'athlete_providers.dart';

class LinkParentScreen extends ConsumerStatefulWidget {
  const LinkParentScreen({super.key, required this.athleteId});

  final String athleteId;

  @override
  ConsumerState<LinkParentScreen> createState() => _LinkParentScreenState();
}

class _LinkParentScreenState extends ConsumerState<LinkParentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  String _relationType = 'parent';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
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

    final result = await ref
        .read(athleteRepositoryProvider)
        .linkParentByEmail(
          athleteId: widget.athleteId,
          email: _emailController.text,
          relationType: _relationType,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Genitore/tutore collegato correttamente.'),
          ),
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
      appBar: AppBar(title: const Text('Collega tutore')),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Collega genitore o tutore',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inserisci l’email di un utente già registrato e già appartenente al club. Se non esiste, crea prima un invito come genitore/tutore.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF52616B)),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email genitore/tutore',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  final email = value ?? '';

                  if (email.isBlank) {
                    return 'Inserisci l’email.';
                  }

                  if (!email.isValidEmail) {
                    return 'Inserisci un indirizzo email valido.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _relationType,
                decoration: const InputDecoration(
                  labelText: 'Tipo relazione',
                  prefixIcon: Icon(Icons.family_restroom_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'parent', child: Text('Genitore')),
                  DropdownMenuItem(value: 'mother', child: Text('Madre')),
                  DropdownMenuItem(value: 'father', child: Text('Padre')),
                  DropdownMenuItem(value: 'guardian', child: Text('Tutore')),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _relationType = value;
                        });
                      },
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: 'Collega',
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
