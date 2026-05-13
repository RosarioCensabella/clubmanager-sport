import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../domain/fee_summary.dart';
import 'fee_providers.dart';

class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});

  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> {
  late Future<AppResult<List<FeeSummary>>> _future;

  String? _activeClubId;

  @override
  void initState() {
    super.initState();
    _future = _loadFees();
  }

  Future<AppResult<List<FeeSummary>>> _loadFees() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final feeRepository = ref.read(feeRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return const AppFailure(
        'Seleziona o crea un club prima di gestire le quote.',
        code: 'active_club_missing',
      );
    }

    return feeRepository.fetchFeesForClub(clubId: _activeClubId!);
  }

  void _reload() {
    setState(() {
      _future = _loadFees();
    });
  }

  void _goToCreateFee() {
    context.push('/fees/create').then((_) => _reload());
  }

  void _goToDetail(FeeSummary fee) {
    context.push('/fees/${fee.id}').then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote associative'),
        actions: [
          IconButton(
            tooltip: 'Nuova quota',
            onPressed: _goToCreateFee,
            icon: const Icon(Icons.add_card_outlined),
          ),
        ],
      ),
      body: FutureBuilder<AppResult<List<FeeSummary>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(message: 'Caricamento quote...');
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
                  icon: Icons.payments_outlined,
                  title: 'Nessuna quota',
                  message:
                      'Crea quote associative, iscrizioni, rate o altri pagamenti da tracciare.',
                  actionLabel: 'Crea quota',
                  onActionPressed: _goToCreateFee,
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
                    final fee = data[index];

                    return _FeeCard(fee: fee, onTap: () => _goToDetail(fee));
                  },
                ),
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreateFee,
        icon: const Icon(Icons.add),
        label: const Text('Nuova quota'),
      ),
    );
  }
}

class _FeeCard extends StatelessWidget {
  const _FeeCard({required this.fee, required this.onTap});

  final FeeSummary fee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = fee.assignmentsCount == 0
        ? 0.0
        : fee.paidCount / fee.assignmentsCount;

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
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.payments_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fee.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fee.amountLabel} · ${fee.scopeLabel}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF52616B),
                      ),
                    ),
                    if (fee.description != null &&
                        fee.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(fee.description!),
                    ],
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text('Assegnate: ${fee.assignmentsCount}'),
                          avatar: const Icon(Icons.group_outlined, size: 18),
                        ),
                        Chip(
                          label: Text('Pagate: ${fee.paidCount}'),
                          avatar: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                        ),
                        Chip(
                          label: Text('Da pagare: ${fee.unpaidCount}'),
                          avatar: const Icon(
                            Icons.pending_actions_outlined,
                            size: 18,
                          ),
                        ),
                        Chip(
                          label: Text('Scadenza: ${fee.dueDateLabel}'),
                          avatar: const Icon(
                            Icons.event_available_outlined,
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
}
