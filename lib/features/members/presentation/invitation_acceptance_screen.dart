import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/invitation_acceptance.dart';
import 'invitation_providers.dart';

class InvitationAcceptanceScreen extends ConsumerStatefulWidget {
  const InvitationAcceptanceScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<InvitationAcceptanceScreen> createState() =>
      _InvitationAcceptanceScreenState();
}

class _InvitationAcceptanceScreenState
    extends ConsumerState<InvitationAcceptanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();

  late Future<AppResult<InvitationAcceptance>> _future;

  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _future = _loadInvitation();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<AppResult<InvitationAcceptance>> _loadInvitation() {
    return ref
        .read(invitationRepositoryProvider)
        .fetchInvitationByToken(token: widget.token);
  }

  void _reload() {
    setState(() {
      _future = _loadInvitation();
    });
  }

  Future<void> _acceptAsLoggedUser(InvitationAcceptance invitation) async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await ref
        .read(invitationRepositoryProvider)
        .acceptInvitation(token: invitation.token);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invito accettato correttamente.')),
        );
        context.go('/club-context');

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _createAccountAndAccept(InvitationAcceptance invitation) async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isSubmitting) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devi accettare privacy policy e termini di servizio.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final authResult = await ref
        .read(authControllerProvider)
        .signUp(
          email: invitation.email,
          password: _passwordController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
        );

    if (!mounted) {
      return;
    }

    switch (authResult) {
      case AppFailure(:final message):
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));

      case AppSuccess(:final data):
        if (data == null) {
          setState(() {
            _isSubmitting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account creato. Controlla la tua email, conferma l’account e poi riapri il link di invito.',
              ),
            ),
          );
          context.go('/login');
          return;
        }

        final acceptResult = await ref
            .read(invitationRepositoryProvider)
            .acceptInvitation(token: invitation.token);

        if (!mounted) {
          return;
        }

        setState(() {
          _isSubmitting = false;
        });

        switch (acceptResult) {
          case AppSuccess():
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account creato e invito accettato.'),
              ),
            );
            context.go('/club-context');

          case AppFailure(:final message):
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
            context.go('/login');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Accetta invito')),
      body: FutureBuilder<AppResult<InvitationAcceptance>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(message: 'Verifica invito...');
          }

          final result = snapshot.data;

          if (result == null) {
            return AppErrorView(
              message: 'Risposta non valida durante la verifica invito.',
              onRetry: _reload,
            );
          }

          switch (result) {
            case AppFailure(:final message):
              return AppErrorView(message: message, onRetry: _reload);

            case AppSuccess(:final data):
              return SafeArea(
                minimum: const EdgeInsets.all(24),
                child: ListView(
                  children: [
                    _InvitationCard(invitation: data),
                    const SizedBox(height: 12),
                    if (!data.isValid)
                      _InvalidInvitationCard(invitation: data)
                    else if (currentUser != null)
                      _LoggedUserAcceptanceCard(
                        invitation: data,
                        currentEmail: currentUser.email,
                        isSubmitting: _isSubmitting,
                        onAccept: () => _acceptAsLoggedUser(data),
                      )
                    else
                      _CreateAccountForm(
                        formKey: _formKey,
                        invitation: data,
                        firstNameController: _firstNameController,
                        lastNameController: _lastNameController,
                        passwordController: _passwordController,
                        acceptedTerms: _acceptedTerms,
                        obscurePassword: _obscurePassword,
                        isSubmitting: _isSubmitting,
                        onAcceptedTermsChanged: (value) {
                          setState(() {
                            _acceptedTerms = value;
                          });
                        },
                        onTogglePassword: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        onSubmit: () => _createAccountAndAccept(data),
                      ),
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({required this.invitation});

  final InvitationAcceptance invitation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invito a ${invitation.clubName}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text('Email invitata: ${invitation.email}'),
            const SizedBox(height: 6),
            Text('Ruolo: ${invitation.roleLabel}'),
            if ((invitation.teamName ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Squadra: ${invitation.teamName}'),
            ],
            const SizedBox(height: 6),
            Text('Stato: ${invitation.statusLabel}'),
            const SizedBox(height: 6),
            Text('Scadenza: ${invitation.expiresAtLabel}'),
          ],
        ),
      ),
    );
  }
}

class _InvalidInvitationCard extends StatelessWidget {
  const _InvalidInvitationCard({required this.invitation});

  final InvitationAcceptance invitation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Questo invito non può essere usato. Stato: ${invitation.statusLabel}. Contatta l’amministratore del club.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoggedUserAcceptanceCard extends StatelessWidget {
  const _LoggedUserAcceptanceCard({
    required this.invitation,
    required this.currentEmail,
    required this.isSubmitting,
    required this.onAccept,
  });

  final InvitationAcceptance invitation;
  final String currentEmail;
  final bool isSubmitting;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final emailMatches =
        currentEmail.trim().toLowerCase() == invitation.email.toLowerCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Account già connesso',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text('Stai usando: $currentEmail'),
            const SizedBox(height: 16),
            if (!emailMatches)
              const Text(
                'Questo invito è associato a un’altra email. Esci e accedi con l’email invitata.',
              )
            else
              AppPrimaryButton(
                label: 'Accetta invito',
                isLoading: isSubmitting,
                onPressed: onAccept,
              ),
          ],
        ),
      ),
    );
  }
}

class _CreateAccountForm extends StatelessWidget {
  const _CreateAccountForm({
    required this.formKey,
    required this.invitation,
    required this.firstNameController,
    required this.lastNameController,
    required this.passwordController,
    required this.acceptedTerms,
    required this.obscurePassword,
    required this.isSubmitting,
    required this.onAcceptedTermsChanged,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final InvitationAcceptance invitation;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController passwordController;
  final bool acceptedTerms;
  final bool obscurePassword;
  final bool isSubmitting;
  final ValueChanged<bool> onAcceptedTermsChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Crea account da invito',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Userai l’email invitata: ${invitation.email}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF52616B),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: firstNameController,
                enabled: !isSubmitting,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  final firstName = value ?? '';

                  if (firstName.isBlank) {
                    return 'Inserisci il tuo nome.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: lastNameController,
                enabled: !isSubmitting,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.familyName],
                decoration: const InputDecoration(
                  labelText: 'Cognome',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  final lastName = value ?? '';

                  if (lastName.isBlank) {
                    return 'Inserisci il tuo cognome.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: invitation.email,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                enabled: !isSubmitting,
                obscureText: obscurePassword,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: 'Minimo 8 caratteri.',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: isSubmitting ? null : onTogglePassword,
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  final password = value ?? '';

                  if (password.isBlank) {
                    return 'Inserisci una password.';
                  }

                  if (password.length < 8) {
                    return 'La password deve avere almeno 8 caratteri.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: acceptedTerms,
                onChanged: isSubmitting
                    ? null
                    : (value) => onAcceptedTermsChanged(value ?? false),
                title: const Text(
                  'Accetto privacy policy e termini di servizio.',
                ),
              ),
              const SizedBox(height: 16),
              AppPrimaryButton(
                label: 'Crea account e accetta invito',
                isLoading: isSubmitting,
                onPressed: onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
