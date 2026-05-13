import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../domain/notification_preferences.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Future<AppResult<NotificationPreferences>> _future;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _future = _loadPreferences();
  }

  Future<AppResult<NotificationPreferences>> _loadPreferences() {
    return ref.read(settingsRepositoryProvider).fetchNotificationPreferences();
  }

  void _reload() {
    setState(() {
      _future = _loadPreferences();
    });
  }

  void _goToPrivacy() {
    context.push('/privacy');
  }

  Future<void> _save(NotificationPreferences preferences) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final result = await ref
        .read(settingsRepositoryProvider)
        .updateNotificationPreferences(preferences: preferences);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    switch (result) {
      case AppSuccess(:final data):
        setState(() {
          _future = Future<AppResult<NotificationPreferences>>.value(
            AppSuccess(data),
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impostazioni aggiornate.')),
        );

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showOperationalInfo() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Comunicazioni operative'),
          content: const Text(
            'Le notifiche operative riguardano attività del club come eventi, convocazioni, documenti e quote. Puoi disattivarle per categoria, ma alcune comunicazioni importanti potrebbero comunque essere visibili dentro l’app.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Ho capito'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        actions: [
          IconButton(
            tooltip: 'Aggiorna',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<AppResult<NotificationPreferences>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(message: 'Caricamento impostazioni...');
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
              return SafeArea(
                minimum: const EdgeInsets.all(24),
                child: ListView(
                  children: [
                    _HeaderCard(isSaving: _isSaving),
                    const SizedBox(height: 12),
                    _NotificationSettingsCard(
                      preferences: data,
                      isSaving: _isSaving,
                      onChanged: _save,
                      onInfoPressed: _showOperationalInfo,
                    ),
                    const SizedBox(height: 12),
                    _PrivacyAccountCard(onPressed: _goToPrivacy),
                    const SizedBox(height: 12),
                    const _PrivacyInfoCard(),
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.isSaving});

  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.settings_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferenze app',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSaving
                        ? 'Salvataggio in corso...'
                        : 'Gestisci notifiche, privacy e preferenze operative.',
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

class _NotificationSettingsCard extends StatelessWidget {
  const _NotificationSettingsCard({
    required this.preferences,
    required this.isSaving,
    required this.onChanged,
    required this.onInfoPressed,
  });

  final NotificationPreferences preferences;
  final bool isSaving;
  final ValueChanged<NotificationPreferences> onChanged;
  final VoidCallback onInfoPressed;

  @override
  Widget build(BuildContext context) {
    final childSwitchesEnabled = preferences.pushEnabled && !isSaving;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Notifiche push'),
              subtitle: const Text(
                'Abilita o disabilita le notifiche push sul dispositivo.',
              ),
              trailing: Switch(
                value: preferences.pushEnabled,
                onChanged: isSaving
                    ? null
                    : (value) {
                        onChanged(
                          preferences.copyWith(
                            pushEnabled: value,
                            eventNotificationsEnabled:
                                value && preferences.eventNotificationsEnabled,
                            communicationNotificationsEnabled:
                                value &&
                                preferences.communicationNotificationsEnabled,
                            documentNotificationsEnabled:
                                value &&
                                preferences.documentNotificationsEnabled,
                            feeNotificationsEnabled:
                                value && preferences.feeNotificationsEnabled,
                          ),
                        );
                      },
              ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              value: preferences.eventNotificationsEnabled,
              onChanged: childSwitchesEnabled
                  ? (value) {
                      onChanged(
                        preferences.copyWith(eventNotificationsEnabled: value),
                      );
                    }
                  : null,
              secondary: const Icon(Icons.event_outlined),
              title: const Text('Eventi e calendario'),
              subtitle: const Text(
                'Allenamenti, partite, convocazioni e promemoria evento.',
              ),
            ),
            SwitchListTile(
              value: preferences.communicationNotificationsEnabled,
              onChanged: childSwitchesEnabled
                  ? (value) {
                      onChanged(
                        preferences.copyWith(
                          communicationNotificationsEnabled: value,
                        ),
                      );
                    }
                  : null,
              secondary: const Icon(Icons.campaign_outlined),
              title: const Text('Comunicazioni'),
              subtitle: const Text(
                'Avvisi del club, messaggi importanti e aggiornamenti.',
              ),
            ),
            SwitchListTile(
              value: preferences.documentNotificationsEnabled,
              onChanged: childSwitchesEnabled
                  ? (value) {
                      onChanged(
                        preferences.copyWith(
                          documentNotificationsEnabled: value,
                        ),
                      );
                    }
                  : null,
              secondary: const Icon(Icons.folder_copy_outlined),
              title: const Text('Documenti e scadenze'),
              subtitle: const Text(
                'Certificati medici, documenti richiesti e promemoria scadenze.',
              ),
            ),
            SwitchListTile(
              value: preferences.feeNotificationsEnabled,
              onChanged: childSwitchesEnabled
                  ? (value) {
                      onChanged(
                        preferences.copyWith(feeNotificationsEnabled: value),
                      );
                    }
                  : null,
              secondary: const Icon(Icons.payments_outlined),
              title: const Text('Quote associative'),
              subtitle: const Text(
                'Scadenze pagamento, solleciti e aggiornamenti amministrativi.',
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Come funzionano le notifiche operative'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onInfoPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyAccountCard extends StatelessWidget {
  const _PrivacyAccountCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.privacy_tip_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Privacy e account'),
        subtitle: const Text(
          'Informazioni privacy e richiesta eliminazione account.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onPressed,
      ),
    );
  }
}

class _PrivacyInfoCard extends StatelessWidget {
  const _PrivacyInfoCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Queste preferenze controllano l’invio di notifiche push. I dati operativi del club restano protetti da ruoli e permessi lato backend.',
            ),
          ],
        ),
      ),
    );
  }
}
