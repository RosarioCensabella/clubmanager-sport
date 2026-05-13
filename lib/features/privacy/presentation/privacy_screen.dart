import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../domain/account_deletion_request.dart';
import 'privacy_providers.dart';

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  late Future<AppResult<AccountDeletionRequest?>> _future;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _future = _loadLatestRequest();
  }

  Future<AppResult<AccountDeletionRequest?>> _loadLatestRequest() {
    return ref.read(privacyRepositoryProvider).fetchLatestDeletionRequest();
  }

  void _reload() {
    setState(() {
      _future = _loadLatestRequest();
    });
  }

  Future<void> _requestDeletion() async {
    if (_isSubmitting) {
      return;
    }

    final reason = await _showDeletionReasonDialog();

    if (reason == null || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await ref
        .read(privacyRepositoryProvider)
        .requestAccountDeletion(reason: reason);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Richiesta di eliminazione account inviata.'),
          ),
        );
        _reload();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _cancelDeletionRequest(AccountDeletionRequest request) async {
    if (_isSubmitting) {
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Annullare richiesta?'),
          content: const Text(
            'La richiesta di eliminazione account verrà annullata. Potrai crearne una nuova in futuro.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Annulla richiesta'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await ref
        .read(privacyRepositoryProvider)
        .cancelDeletionRequest(requestId: request.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Richiesta annullata.')));
        _reload();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<String?> _showDeletionReasonDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminazione account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'La richiesta verrà salvata e processata in modo sicuro. Inserisci un motivo facoltativo.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo facoltativo',
                  hintText: 'Es. Non uso più l’app',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text);
              },
              child: const Text('Invia richiesta'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy e account'),
        actions: [
          IconButton(
            tooltip: 'Aggiorna',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<AppResult<AccountDeletionRequest?>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(message: 'Caricamento privacy...');
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
                    const _PrivacyIntroCard(),
                    const SizedBox(height: 12),
                    _DeletionRequestCard(
                      request: data,
                      isSubmitting: _isSubmitting,
                      onRequestDeletion: _requestDeletion,
                      onCancelRequest: data == null
                          ? null
                          : () => _cancelDeletionRequest(data),
                    ),
                    const SizedBox(height: 12),
                    const _DataProtectionCard(),
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}

class _PrivacyIntroCard extends StatelessWidget {
  const _PrivacyIntroCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy e dati personali',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gestisci le richieste relative al tuo account. I dati del club sono protetti da ruoli, permessi e policy Supabase.',
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

class _DeletionRequestCard extends StatelessWidget {
  const _DeletionRequestCard({
    required this.request,
    required this.isSubmitting,
    required this.onRequestDeletion,
    required this.onCancelRequest,
  });

  final AccountDeletionRequest? request;
  final bool isSubmitting;
  final VoidCallback onRequestDeletion;
  final VoidCallback? onCancelRequest;

  @override
  Widget build(BuildContext context) {
    final currentRequest = request;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Eliminazione account',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Puoi richiedere l’eliminazione del tuo account. La richiesta verrà tracciata e processata in modo sicuro.',
            ),
            const SizedBox(height: 16),
            if (currentRequest == null)
              const _StatusBox(
                icon: Icons.info_outline,
                title: 'Nessuna richiesta attiva',
                message:
                    'Non hai richieste di eliminazione account registrate.',
              )
            else
              _StatusBox(
                icon: currentRequest.isPending
                    ? Icons.pending_actions_outlined
                    : Icons.fact_check_outlined,
                title: 'Stato: ${currentRequest.statusLabel}',
                message:
                    'Richiesta del ${currentRequest.requestedAtLabel}. Ultimo aggiornamento: ${currentRequest.updatedAtLabel}.',
              ),
            if (currentRequest != null && currentRequest.reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Motivo: ${currentRequest.reason}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            if (currentRequest?.isPending == true)
              OutlinedButton.icon(
                onPressed: isSubmitting ? null : onCancelRequest,
                icon: const Icon(Icons.cancel_outlined),
                label: Text(
                  isSubmitting ? 'Operazione in corso...' : 'Annulla richiesta',
                ),
              )
            else
              FilledButton.icon(
                onPressed: isSubmitting ? null : onRequestDeletion,
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  isSubmitting
                      ? 'Invio in corso...'
                      : 'Richiedi eliminazione account',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD4DEE7)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataProtectionCard extends StatelessWidget {
  const _DataProtectionCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Protezione dati',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'L’app usa policy di sicurezza lato database per limitare l’accesso ai dati in base all’utente autenticato, al club e al ruolo assegnato.',
            ),
            SizedBox(height: 8),
            Text(
              'La cancellazione definitiva dell’account verrà completata lato backend, così da gestire correttamente dati collegati, audit e obblighi amministrativi.',
            ),
          ],
        ),
      ),
    );
  }
}
