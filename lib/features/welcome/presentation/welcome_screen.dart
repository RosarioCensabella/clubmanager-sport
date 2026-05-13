import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Benvenuto')),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              'Organizza il tuo club in un’unica app',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ClubManager Sport è un gestionale per società sportive. Gli accessi vengono creati tramite invito dal club.',
              style: textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF52616B),
              ),
            ),
            const SizedBox(height: 24),
            const _FeatureCard(
              icon: Icons.groups,
              title: 'Gestionale multi-club',
              description:
                  'Gestisci club, squadre, atleti, staff, genitori e ruoli.',
            ),
            const SizedBox(height: 12),
            const _FeatureCard(
              icon: Icons.event,
              title: 'Eventi e operatività',
              description:
                  'Crea eventi, convocazioni, presenze, comunicazioni e documenti.',
            ),
            const SizedBox(height: 12),
            const _FeatureCard(
              icon: Icons.verified_user,
              title: 'Accessi controllati',
              description:
                  'Nessuna registrazione libera: ogni account nasce da invito.',
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Accedi'),
            ),
            const SizedBox(height: 12),
            const _InviteInfoCard(),
          ],
        ),
      ),
    );
  }
}

class _InviteInfoCard extends StatelessWidget {
  const _InviteInfoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hai ricevuto un invito?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Apri il link ricevuto dal tuo club per completare la creazione dell’account o collegare un account esistente.',
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
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
