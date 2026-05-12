import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../domain/communication_summary.dart';
import 'communication_providers.dart';

class CommunicationsScreen extends ConsumerStatefulWidget {
  const CommunicationsScreen({super.key});

  @override
  ConsumerState<CommunicationsScreen> createState() =>
      _CommunicationsScreenState();
}

class _CommunicationsScreenState extends ConsumerState<CommunicationsScreen> {
  late Future<AppResult<List<CommunicationSummary>>> _future;

  String? _activeClubId;

  @override
  void initState() {
    super.initState();
    _future = _loadCommunications();
  }

  Future<AppResult<List<CommunicationSummary>>> _loadCommunications() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final communicationRepository = ref.read(communicationRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return const AppFailure(
        'Seleziona o crea un club prima di gestire le comunicazioni.',
        code: 'active_club_missing',
      );
    }

    return communicationRepository.fetchCommunicationsForClub(
      clubId: _activeClubId!,
    );
  }

  void _reload() {
    setState(() {
      _future = _loadCommunications();
    });
  }

  void _goToCreateCommunication() {
    context.push('/communications/create').then((_) => _reload());
  }

  void _goToDetail(CommunicationSummary communication) {
    context.push('/communications/${communication.id}').then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunicazioni'),
        actions: [
          IconButton(
            tooltip: 'Nuova comunicazione',
            onPressed: _goToCreateCommunication,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: FutureBuilder<AppResult<List<CommunicationSummary>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(
              message: 'Caricamento comunicazioni...',
            );
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
              if (data.isEmpty) {
                return AppEmptyState(
                  icon: Icons.campaign_outlined,
                  title: 'Nessuna comunicazione',
                  message:
                      'Crea comunicazioni ufficiali per tutto il club o per una squadra.',
                  actionLabel: 'Crea comunicazione',
                  onActionPressed: _goToCreateCommunication,
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _reload();
                  await _future;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: data.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final communication = data[index];

                    return _CommunicationCard(
                      communication: communication,
                      onTap: () => _goToDetail(communication),
                    );
                  },
                ),
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreateCommunication,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Nuova'),
      ),
    );
  }
}

class _CommunicationCard extends StatelessWidget {
  const _CommunicationCard({required this.communication, required this.onTap});

  final CommunicationSummary communication;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color,
                foregroundColor: Colors.white,
                child: const Icon(Icons.campaign_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      communication.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: communication.isRead
                            ? FontWeight.w700
                            : FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _previewText(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF52616B),
                      ),
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
                          label: Text(communication.isRead ? 'Letta' : 'Nuova'),
                          avatar: Icon(
                            communication.isRead
                                ? Icons.mark_email_read_outlined
                                : Icons.mark_email_unread_outlined,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _previewText() {
    final text = communication.body.trim();

    if (text.isEmpty) {
      return 'Nessun testo.';
    }

    return text;
  }

  Color _priorityColor() {
    switch (communication.priority) {
      case 'urgent':
        return const Color(0xFFC62828);
      case 'important':
        return const Color(0xFFF9A825);
      default:
        return const Color(0xFF176B87);
    }
  }
}
