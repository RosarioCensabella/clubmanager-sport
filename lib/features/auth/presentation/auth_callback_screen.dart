import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthCallbackScreen extends StatelessWidget {
  const AuthCallbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifica email')),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(
              Icons.mark_email_read_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Email verificata',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              'Se la verifica è andata a buon fine, ora puoi accedere con email e password.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF52616B)),
            ),
            const Spacer(),
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
