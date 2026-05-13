import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key, this.invitationToken});

  final String? invitationToken;

  @override
  Widget build(BuildContext context) {
    final token = invitationToken?.trim() ?? '';
    final hasToken = token.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(hasToken ? 'Invito ricevuto' : 'Registrazione'),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Icon(
              hasToken
                  ? Icons.mark_email_read_outlined
                  : Icons.lock_person_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              hasToken
                  ? 'Registrazione da invito'
                  : 'Registrazione libera non disponibile',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              hasToken
                  ? 'Hai aperto un link di invito. Nel prossimo step completeremo la creazione account e il collegamento automatico al club.'
                  : 'Per usare ClubManager Sport devi ricevere un invito da un club. Contatta l’amministratore del tuo club se non hai ancora ricevuto il link.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF52616B)),
            ),
            if (hasToken) ...[
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: SelectableText.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Token invito: ',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: token),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Vai al login'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/welcome'),
              child: const Text('Torna al benvenuto'),
            ),
          ],
        ),
      ),
    );
  }
}
