import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../domain/user_profile.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  late Future<AppResult<UserProfile>> _future;

  bool _isSaving = false;
  bool _isSigningOut = false;
  bool _marketingConsent = false;
  bool _initializedForm = false;

  @override
  void initState() {
    super.initState();
    _future = _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<AppResult<UserProfile>> _loadProfile() async {
    return ref.read(profileRepositoryProvider).fetchCurrentProfile();
  }

  void _reload() {
    setState(() {
      _initializedForm = false;
      _future = _loadProfile();
    });
  }

  void _initForm(UserProfile profile) {
    if (_initializedForm) {
      return;
    }

    _initializedForm = true;
    _fullNameController.text = profile.fullName;
    _phoneNumberController.text = profile.phoneNumber;
    _marketingConsent = profile.marketingConsent;
  }

  void _goToSettings() {
    context.push('/settings');
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final result = await ref
        .read(profileRepositoryProvider)
        .updateCurrentProfile(
          fullName: _fullNameController.text,
          phoneNumber: _phoneNumberController.text,
          marketingConsent: _marketingConsent,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    switch (result) {
      case AppSuccess(:final data):
        _initializedForm = false;
        _initForm(data);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profilo aggiornato.')));

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _signOut() async {
    if (_isSigningOut) {
      return;
    }

    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Uscire dall’account?'),
          content: const Text(
            'Dovrai effettuare nuovamente l’accesso per usare l’app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Esci'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true || !mounted) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    final result = await ref.read(profileRepositoryProvider).signOut();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSigningOut = false;
    });

    switch (result) {
      case AppSuccess():
        context.go('/welcome');

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String? _validateFullName(String? value) {
    final text = value ?? '';

    if (text.isBlank) {
      return 'Inserisci nome e cognome.';
    }

    if (text.trim().length < 2) {
      return 'Il nome è troppo breve.';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final valid = RegExp(r'^[0-9+\s().-]{6,20}$').hasMatch(text);

    if (!valid) {
      return 'Inserisci un numero di telefono valido.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo utente'),
        actions: [
          IconButton(
            tooltip: 'Impostazioni',
            onPressed: _goToSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Aggiorna',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<AppResult<UserProfile>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(message: 'Caricamento profilo...');
          }

          final result = snapshot.data;

          if (result == null) {
            return AppErrorView(
              message: 'Risposta non valida durante il caricamento.',
              onRetry: _reload,
            );
          }

          switch (result) {
            case AppFailure(:final message):
              return AppErrorView(message: message, onRetry: _reload);

            case AppSuccess(:final data):
              _initForm(data);

              return SafeArea(
                minimum: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      _ProfileHeader(profile: data),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _isSaving || _isSigningOut
                            ? null
                            : _goToSettings,
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Impostazioni notifiche'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Dati personali',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _fullNameController,
                        enabled: !_isSaving && !_isSigningOut,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nome e cognome',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _validateFullName,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneNumberController,
                        enabled: !_isSaving && !_isSigningOut,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Telefono',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: _marketingConsent,
                        onChanged: _isSaving || _isSigningOut
                            ? null
                            : (value) {
                                setState(() {
                                  _marketingConsent = value;
                                });
                              },
                        title: const Text('Consenso comunicazioni marketing'),
                        subtitle: const Text(
                          'Disattivato di default. Non influenza le comunicazioni operative del club.',
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppPrimaryButton(
                        label: 'Salva profilo',
                        isLoading: _isSaving,
                        onPressed: _save,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isSaving || _isSigningOut ? null : _signOut,
                        icon: const Icon(Icons.logout),
                        label: Text(_isSigningOut ? 'Uscita...' : 'Esci'),
                      ),
                      const SizedBox(height: 24),
                      _AccountInfoCard(profile: data),
                    ],
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              child: Text(
                profile.initials,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF52616B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informazioni account',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'ID utente', value: profile.id),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Lingua',
              value: profile.preferredLanguage.toUpperCase(),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Onboarding',
              value: profile.onboardingCompleted
                  ? 'Completato'
                  : 'Da completare',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
