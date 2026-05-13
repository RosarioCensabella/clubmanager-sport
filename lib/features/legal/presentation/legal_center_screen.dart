import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/config/app_store_config.dart';
import '../domain/legal_document.dart';

class LegalCenterScreen extends StatefulWidget {
  const LegalCenterScreen({super.key});

  @override
  State<LegalCenterScreen> createState() => _LegalCenterScreenState();
}

class _LegalCenterScreenState extends State<LegalCenterScreen> {
  late Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  void _openDocument(String documentId) {
    context.push('/legal/$documentId');
  }

  void _openPrivacyFlow() {
    context.push('/privacy');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documenti legali')),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const _HeaderCard(),
            const SizedBox(height: 12),
            for (final document in LegalDocuments.all) ...[
              _LegalDocumentTile(
                document: document,
                onTap: () => _openDocument(document.id),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            _AccountDeletionTile(onTap: _openPrivacyFlow),
            const SizedBox(height: 12),
            FutureBuilder<PackageInfo>(
              future: _packageInfoFuture,
              builder: (context, snapshot) {
                final packageInfo = snapshot.data;

                return _AppInfoCard(packageInfo: packageInfo);
              },
            ),
            const SizedBox(height: 12),
            const _StoreReadinessCard(),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.gavel_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compliance base',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Informazioni legali, privacy, dati account e preparazione alla pubblicazione sugli store.',
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

class _LegalDocumentTile extends StatelessWidget {
  const _LegalDocumentTile({required this.document, required this.onTap});

  final LegalDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(document.title),
        subtitle: Text(document.subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _AccountDeletionTile extends StatelessWidget {
  const _AccountDeletionTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.delete_outline),
        title: const Text('Richiesta eliminazione account'),
        subtitle: const Text('Apri la schermata Privacy e account.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _AppInfoCard extends StatelessWidget {
  const _AppInfoCard({required this.packageInfo});

  final PackageInfo? packageInfo;

  @override
  Widget build(BuildContext context) {
    final version = packageInfo == null
        ? 'Non disponibile'
        : '${packageInfo!.version}+${packageInfo!.buildNumber}';

    final packageName = packageInfo?.packageName ?? 'Non disponibile';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informazioni app',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Nome app', value: AppStoreConfig.appName),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Sviluppatore',
              value: AppStoreConfig.developerName,
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'Supporto', value: AppStoreConfig.supportEmail),
            const SizedBox(height: 8),
            _InfoRow(label: 'Versione', value: version),
            const SizedBox(height: 8),
            _InfoRow(label: 'Package', value: packageName),
          ],
        ),
      ),
    );
  }
}

class _StoreReadinessCard extends StatelessWidget {
  const _StoreReadinessCard();

  @override
  Widget build(BuildContext context) {
    final privacyReady = AppStoreConfig.hasPublicPrivacyPolicyUrl;
    final termsReady = AppStoreConfig.hasPublicTermsUrl;
    final deletionReady = AppStoreConfig.hasPublicAccountDeletionUrl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checklist store',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _ChecklistRow(
              completed: privacyReady,
              label: privacyReady
                  ? 'Privacy policy pubblica configurata'
                  : 'Privacy policy pubblica da configurare',
            ),
            const SizedBox(height: 8),
            _ChecklistRow(
              completed: termsReady,
              label: termsReady
                  ? 'Termini d’uso pubblici configurati'
                  : 'Termini d’uso pubblici da configurare',
            ),
            const SizedBox(height: 8),
            _ChecklistRow(
              completed: deletionReady,
              label: deletionReady
                  ? 'Link web eliminazione account configurato'
                  : 'Link web eliminazione account da configurare',
            ),
            const SizedBox(height: 12),
            const Text(
              'Questa checklist serve a ricordare cosa manca prima della pubblicazione sugli store.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.completed, required this.label});

  final bool completed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          completed ? Icons.check_circle_outline : Icons.pending_outlined,
          color: completed ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
      ],
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
