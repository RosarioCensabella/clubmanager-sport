import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_store_config.dart';
import '../../../core/services/supabase_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late Future<_SupportInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadSupportInfo();
  }

  Future<_SupportInfo> _loadSupportInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final user = SupabaseService.isConfigured
        ? SupabaseService.client.auth.currentUser
        : null;

    return _SupportInfo(
      appName: packageInfo.appName,
      packageName: packageInfo.packageName,
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      platform: _platformName(),
      isSupabaseConfigured: SupabaseService.isConfigured,
      userId: user?.id ?? '',
      userEmail: user?.email ?? '',
    );
  }

  String _platformName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }

  Future<void> _contactSupport(_SupportInfo info) async {
    final subject = Uri.encodeComponent('Supporto ${AppStoreConfig.appName}');

    final body = Uri.encodeComponent('''
Ciao,
ho bisogno di supporto per ${AppStoreConfig.appName}.

Descrizione problema:


---
Informazioni tecniche:
App: ${info.appName}
Package: ${info.packageName}
Versione: ${info.version}+${info.buildNumber}
Piattaforma: ${info.platform}
Supabase configurato: ${info.isSupabaseConfigured ? 'sì' : 'no'}
User ID: ${info.userId.isEmpty ? 'non disponibile' : info.userId}
Email: ${info.userEmail.isEmpty ? 'non disponibile' : info.userEmail}
''');

    final uri = Uri.parse(
      'mailto:${AppStoreConfig.supportEmail}?subject=$subject&body=$body',
    );

    if (!await launchUrl(uri)) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Non riesco ad aprire l’app email. Scrivi a ${AppStoreConfig.supportEmail}.',
          ),
        ),
      );
    }
  }

  void _reload() {
    setState(() {
      _future = _loadSupportInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supporto e diagnostica'),
        actions: [
          IconButton(
            tooltip: 'Aggiorna',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_SupportInfo>(
        future: _future,
        builder: (context, snapshot) {
          final info = snapshot.data;

          if (snapshot.connectionState != ConnectionState.done ||
              info == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            minimum: const EdgeInsets.all(24),
            child: ListView(
              children: [
                _HeaderCard(onContactSupport: () => _contactSupport(info)),
                const SizedBox(height: 12),
                _SupportContactCard(
                  onContactSupport: () => _contactSupport(info),
                ),
                const SizedBox(height: 12),
                _DiagnosticCard(info: info),
                const SizedBox(height: 12),
                const _TroubleshootingCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.onContactSupport});

  final VoidCallback onContactSupport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.support_agent_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hai bisogno di aiuto?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Da qui puoi contattare il supporto e copiare le informazioni tecniche utili per diagnosticare problemi.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF52616B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: onContactSupport,
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Contatta supporto'),
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

class _SupportContactCard extends StatelessWidget {
  const _SupportContactCard({required this.onContactSupport});

  final VoidCallback onContactSupport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.alternate_email_outlined),
        title: const Text('Email supporto'),
        subtitle: Text(AppStoreConfig.supportEmail),
        trailing: const Icon(Icons.open_in_new),
        onTap: onContactSupport,
      ),
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard({required this.info});

  final _SupportInfo info;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagnostica',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'App', value: info.appName),
            const SizedBox(height: 8),
            _InfoRow(label: 'Package', value: info.packageName),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Versione',
              value: '${info.version}+${info.buildNumber}',
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'Piattaforma', value: info.platform),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Supabase',
              value: info.isSupabaseConfigured
                  ? 'Configurato'
                  : 'Non configurato',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'User ID',
              value: info.userId.isEmpty ? 'Non disponibile' : info.userId,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Email',
              value: info.userEmail.isEmpty
                  ? 'Non disponibile'
                  : info.userEmail,
            ),
          ],
        ),
      ),
    );
  }
}

class _TroubleshootingCard extends StatelessWidget {
  const _TroubleshootingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prima di contattare il supporto',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('1. Verifica di avere connessione internet.'),
            SizedBox(height: 6),
            Text('2. Chiudi e riapri l’app.'),
            SizedBox(height: 6),
            Text(
              '3. Controlla di aver effettuato l’accesso con l’email corretta.',
            ),
            SizedBox(height: 6),
            Text(
              '4. Se il problema riguarda notifiche, controlla le impostazioni del dispositivo.',
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

class _SupportInfo {
  const _SupportInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    required this.platform,
    required this.isSupabaseConfigured,
    required this.userId,
    required this.userEmail,
  });

  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
  final String platform;
  final bool isSupabaseConfigured;
  final String userId;
  final String userEmail;
}
