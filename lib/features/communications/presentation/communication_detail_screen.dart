import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../domain/communication_summary.dart';
import 'communication_providers.dart';

class CommunicationDetailScreen extends ConsumerStatefulWidget {
  const CommunicationDetailScreen({super.key, required this.communicationId});

  final String communicationId;

  @override
  ConsumerState<CommunicationDetailScreen> createState() =>
      _CommunicationDetailScreenState();
}

class _CommunicationDetailScreenState
    extends ConsumerState<CommunicationDetailScreen> {
  late Future<AppResult<CommunicationSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadCommunication();
  }

  Future<AppResult<CommunicationSummary>> _loadCommunication() async {
    final repository = ref.read(communicationRepositoryProvider);

    final result = await repository.fetchCommunicationById(
      communicationId: widget.communicationId,
    );

    switch (result) {
      case AppFailure():
        return result;

      case AppSuccess(:final data):
        await repository.markAsRead(communicationId: data.id);

        return result;
    }
  }

  void _reload() {
    setState(() {
      _future = _loadCommunication();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<AppResult<CommunicationSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: AppLoadingView(message: 'Caricamento comunicazione...'),
            );
          }

          final result = snapshot.data;

          if (result == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Comunicazione')),
              body: AppErrorView(
                message: 'Risposta non valida durante il caricamento.',
                onRetry: _reload,
              ),
            );
          }

          switch (result) {
            case AppFailure(:final message):
              return Scaffold(
                appBar: AppBar(title: const Text('Comunicazione')),
                body: AppErrorView(message: message, onRetry: _reload),
              );

            case AppSuccess(:final data):
              return Scaffold(
                appBar: AppBar(title: const Text('Comunicazione')),
                body: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [_CommunicationDetailCard(communication: data)],
                ),
              );
          }
        },
      ),
    );
  }
}

class _CommunicationDetailCard extends StatelessWidget {
  const _CommunicationDetailCard({required this.communication});

  final CommunicationSummary communication;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              communication.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(communication.priorityLabel),
                  avatar: const Icon(Icons.priority_high, size: 18),
                ),
                Chip(
                  label: Text(communication.visibilityLabel),
                  avatar: const Icon(Icons.groups_2_outlined, size: 18),
                ),
                Chip(
                  label: Text(_formatDate(communication.createdAt)),
                  avatar: const Icon(Icons.schedule_outlined, size: 18),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              communication.body,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              communication.sendPush
                  ? 'Notifica push richiesta. La spedizione effettiva sarà configurata nella fase notifiche.'
                  : 'Notifica push non richiesta.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF52616B)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString().padLeft(4, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
