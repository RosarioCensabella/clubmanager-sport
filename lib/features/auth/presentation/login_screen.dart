import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../members/presentation/invitation_providers.dart';
import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _invitationCodeController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showInvitationCode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _invitationCodeController.dispose();
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
        .read(authControllerProvider)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AppSuccess():
        final pendingToken = await ref
            .read(invitationRepositoryProvider)
            .getPendingInvitationToken();

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accesso effettuato correttamente.')),
        );

        if (pendingToken != null && pendingToken.isNotEmpty) {
          context.go('/invite/${Uri.encodeComponent(pendingToken)}');
        } else {
          context.go('/club-context');
        }

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openInvitation() async {
    final repository = ref.read(invitationRepositoryProvider);
    final token = repository.extractInvitationToken(
      _invitationCodeController.text,
    );

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci il codice o il link dell’invito.'),
        ),
      );
      return;
    }

    await repository.savePendingInvitationToken(token);

    if (!mounted) {
      return;
    }

    context.push('/invite/${Uri.encodeComponent(token)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accedi')),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Accedi al tuo club',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inserisci email e password per continuare.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF52616B)),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  final email = value ?? '';

                  if (email.isBlank) {
                    return 'Inserisci la tua email.';
                  }

                  if (!email.isValidEmail) {
                    return 'Inserisci un indirizzo email valido.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  final password = value ?? '';

                  if (password.isBlank) {
                    return 'Inserisci la password.';
                  }

                  if (password.length < 8) {
                    return 'La password deve avere almeno 8 caratteri.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.push('/reset-password'),
                  child: const Text('Password dimenticata?'),
                ),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: 'Accedi',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 18),
              _InvitationAccessCard(
                showCodeField: _showInvitationCode,
                controller: _invitationCodeController,
                isLoading: _isLoading,
                onToggleCodeField: () {
                  setState(() {
                    _showInvitationCode = !_showInvitationCode;
                  });
                },
                onOpenInvitation: _openInvitation,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isLoading ? null : () => context.go('/register'),
                child: const Text('Crea un nuovo account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvitationAccessCard extends StatelessWidget {
  const _InvitationAccessCard({
    required this.showCodeField,
    required this.controller,
    required this.isLoading,
    required this.onToggleCodeField,
    required this.onOpenInvitation,
  });

  final bool showCodeField;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onToggleCodeField;
  final VoidCallback onOpenInvitation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hai ricevuto un invito?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Puoi aprire il link ricevuto via email oppure inserire qui il codice/link dell’invito.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF52616B)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isLoading ? null : onToggleCodeField,
              icon: Icon(
                showCodeField
                    ? Icons.keyboard_arrow_up
                    : Icons.confirmation_number_outlined,
              ),
              label: Text(
                showCodeField
                    ? 'Nascondi codice invito'
                    : 'Inserisci codice invito',
              ),
            ),
            if (showCodeField) ...[
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Codice o link invito',
                  hintText: 'clubmanager-sport://app/invite/...',
                  prefixIcon: Icon(Icons.link_outlined),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: isLoading ? null : onOpenInvitation,
                icon: const Icon(Icons.open_in_new_outlined),
                label: const Text('Apri invito'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
