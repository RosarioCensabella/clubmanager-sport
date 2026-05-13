import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../domain/fee_assignment_summary.dart';
import '../domain/fee_summary.dart';
import 'fee_providers.dart';

class FeeDetailScreen extends ConsumerStatefulWidget {
  const FeeDetailScreen({super.key, required this.feeId});

  final String feeId;

  @override
  ConsumerState<FeeDetailScreen> createState() => _FeeDetailScreenState();
}

class _FeeDetailScreenState extends ConsumerState<FeeDetailScreen> {
  late Future<AppResult<_FeeDetailData>> _future;

  final _searchController = TextEditingController();

  bool _isUpdating = false;
  bool _isDeleting = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _future = _loadDetail();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Future<AppResult<_FeeDetailData>> _loadDetail() async {
    final repository = ref.read(feeRepositoryProvider);

    final feeResult = await repository.fetchFeeById(feeId: widget.feeId);

    switch (feeResult) {
      case AppFailure(:final message, :final code):
        return AppFailure(message, code: code);

      case AppSuccess(:final data):
        final fee = data;

        final assignmentsResult = await repository.fetchAssignmentsForFee(
          feeId: widget.feeId,
        );

        switch (assignmentsResult) {
          case AppFailure(:final message, :final code):
            return AppFailure(message, code: code);

          case AppSuccess(:final data):
            return AppSuccess(_FeeDetailData(fee: fee, assignments: data));
        }
    }
  }

  void _reload() {
    if (!mounted) {
      return;
    }

    setState(() {
      _future = _loadDetail();
    });
  }

  List<FeeAssignmentSummary> _filteredAssignments(
    List<FeeAssignmentSummary> assignments,
  ) {
    if (_searchQuery.isEmpty) {
      return assignments;
    }

    return assignments
        .where((assignment) {
          final athlete = assignment.athlete;
          final values = [
            athlete.fullName,
            athlete.firstName,
            athlete.lastName,
            athlete.teamName ?? '',
            athlete.jerseyNumber?.toString() ?? '',
          ].join(' ').toLowerCase();

          return values.contains(_searchQuery);
        })
        .toList(growable: false);
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminare quota?'),
          content: const Text(
            'La quota e le sue assegnazioni saranno rimosse dalla lista. Questa azione serve per correggere quote create per errore.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted || _isDeleting) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    final result = await ref
        .read(feeRepositoryProvider)
        .deleteFee(feeId: widget.feeId);

    if (!mounted) {
      return;
    }

    setState(() {
      _isDeleting = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Quota eliminata.')));
        Navigator.of(context).pop();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _updateStatus({
    required FeeAssignmentSummary assignment,
    required String status,
    double? amountPaid,
  }) async {
    if (_isUpdating || !mounted) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    final result = await ref
        .read(feeRepositoryProvider)
        .updateAssignmentStatus(
          assignmentId: assignment.id,
          status: status,
          amountDue: assignment.amountDue,
          amountPaid: amountPaid,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isUpdating = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_messageForStatus(status))));
        _reload();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _askPartialAmount(FeeAssignmentSummary assignment) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        var amountText = assignment.amountPaid > 0
            ? assignment.amountPaid.toStringAsFixed(2)
            : '';
        String? errorText;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pagamento parziale',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    assignment.athlete.fullName,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Totale quota: ${assignment.amountLabel}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF52616B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    initialValue: amountText,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Importo pagato',
                      hintText: 'Es. 10,00',
                      prefixIcon: const Icon(Icons.euro_outlined),
                      errorText: errorText,
                    ),
                    onChanged: (value) {
                      amountText = value;
                      if (errorText != null) {
                        setSheetState(() {
                          errorText = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                          },
                          child: const Text('Annulla'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final parsed = _parseAmount(amountText);

                            if (parsed == null || parsed <= 0) {
                              setSheetState(() {
                                errorText = 'Inserisci un importo valido.';
                              });
                              return;
                            }

                            if (parsed >= assignment.amountDue) {
                              setSheetState(() {
                                errorText =
                                    'Per importo completo usa il pulsante Pagata.';
                              });
                              return;
                            }

                            Navigator.of(sheetContext).pop(parsed);
                          },
                          child: const Text('Salva'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || amount == null) {
      return;
    }

    await _updateStatus(
      assignment: assignment,
      status: 'partial',
      amountPaid: amount,
    );
  }

  double? _parseAmount(String value) {
    final normalized = value.trim().replaceAll(',', '.');

    return double.tryParse(normalized);
  }

  String _messageForStatus(String status) {
    switch (status) {
      case 'paid':
        return 'Pagamento segnato come pagato.';
      case 'partial':
        return 'Pagamento parziale registrato.';
      case 'waived':
        return 'Quota esonerata.';
      case 'overdue':
        return 'Quota segnata come scaduta.';
      default:
        return 'Pagamento riportato a da pagare.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettaglio quota'),
        actions: [
          IconButton(
            tooltip: 'Elimina quota',
            onPressed: _isDeleting ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: FutureBuilder<AppResult<_FeeDetailData>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(message: 'Caricamento quota...');
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
              final filteredAssignments = _filteredAssignments(
                data.assignments,
              );

              return RefreshIndicator(
                onRefresh: () async {
                  _reload();
                  await _future;
                },
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _FeeHeaderCard(data: data),
                    const SizedBox(height: 12),
                    if (data.assignments.isNotEmpty) ...[
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Cerca atleta',
                          hintText: 'Nome, cognome, squadra o numero maglia',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Cancella ricerca',
                                  onPressed: _searchController.clear,
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Assegnazioni: ${data.assignments.length}'
                            : 'Risultati: ${filteredAssignments.length} di ${data.assignments.length}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF52616B),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (data.assignments.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Text(
                            'Questa quota non ha assegnazioni. Probabilmente è stata creata prima del fix. Puoi eliminarla con l’icona del cestino e crearla di nuovo.',
                          ),
                        ),
                      )
                    else if (filteredAssignments.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Text('Nessun atleta trovato.'),
                        ),
                      )
                    else
                      for (final assignment in filteredAssignments) ...[
                        _AssignmentCard(
                          assignment: assignment,
                          isUpdating: _isUpdating,
                          onStatusPressed: (status) {
                            if (status == 'partial') {
                              _askPartialAmount(assignment);
                              return;
                            }

                            _updateStatus(
                              assignment: assignment,
                              status: status,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}

class _FeeDetailData {
  const _FeeDetailData({required this.fee, required this.assignments});

  final FeeSummary fee;
  final List<FeeAssignmentSummary> assignments;

  int countStatus(String status) {
    return assignments
        .where((assignment) => assignment.status == status)
        .length;
  }

  double get totalDue {
    return assignments.fold<double>(
      0,
      (sum, assignment) => sum + assignment.amountDue,
    );
  }

  double get totalPaid {
    return assignments.fold<double>(
      0,
      (sum, assignment) => sum + assignment.amountPaid,
    );
  }

  double get totalRemaining {
    final remaining = totalDue - totalPaid;

    if (remaining <= 0) {
      return 0;
    }

    return remaining;
  }

  String get totalDueLabel {
    return '${totalDue.toStringAsFixed(2).replaceAll('.', ',')} EUR';
  }

  String get totalPaidLabel {
    return '${totalPaid.toStringAsFixed(2).replaceAll('.', ',')} EUR';
  }

  String get totalRemainingLabel {
    return '${totalRemaining.toStringAsFixed(2).replaceAll('.', ',')} EUR';
  }
}

class _FeeHeaderCard extends StatelessWidget {
  const _FeeHeaderCard({required this.data});

  final _FeeDetailData data;

  @override
  Widget build(BuildContext context) {
    final paid = data.countStatus('paid');
    final partial = data.countStatus('partial');
    final waived = data.countStatus('waived');
    final unpaid = data.countStatus('unpaid');
    final overdue = data.countStatus('overdue');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.fee.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '${data.fee.amountLabel} · ${data.fee.scopeLabel}',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF52616B)),
            ),
            if (data.fee.description != null &&
                data.fee.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(data.fee.description!),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Assegnate: ${data.assignments.length}')),
                Chip(label: Text('Pagate: $paid')),
                Chip(label: Text('Parziali: $partial')),
                Chip(label: Text('Esonerate: $waived')),
                Chip(label: Text('Da pagare: $unpaid')),
                Chip(label: Text('Scadute: $overdue')),
                Chip(label: Text('Scadenza: ${data.fee.dueDateLabel}')),
                Chip(label: Text('Totale: ${data.totalDueLabel}')),
                Chip(label: Text('Incassato: ${data.totalPaidLabel}')),
                Chip(label: Text('Residuo: ${data.totalRemainingLabel}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.isUpdating,
    required this.onStatusPressed,
  });

  final FeeAssignmentSummary assignment;
  final bool isUpdating;
  final ValueChanged<String> onStatusPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(assignment.athlete.initials)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.athlete.fullName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${assignment.amountLabel} · ${assignment.athlete.teamName ?? 'Nessuna squadra'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF52616B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text('Pagato: ${assignment.paidLabel}'),
                            avatar: const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                            ),
                          ),
                          Chip(
                            label: Text(
                              'Residuo: ${assignment.remainingLabel}',
                            ),
                            avatar: const Icon(
                              Icons.pending_actions_outlined,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Chip(label: Text(assignment.statusLabel)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: isUpdating || assignment.isPaid
                      ? null
                      : () => onStatusPressed('paid'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Pagata'),
                ),
                OutlinedButton.icon(
                  onPressed: isUpdating
                      ? null
                      : () => onStatusPressed('partial'),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Parziale'),
                ),
                OutlinedButton.icon(
                  onPressed: isUpdating || assignment.isWaived
                      ? null
                      : () => onStatusPressed('waived'),
                  icon: const Icon(Icons.volunteer_activism_outlined),
                  label: const Text('Esonerata'),
                ),
                OutlinedButton.icon(
                  onPressed: isUpdating || assignment.isOverdue
                      ? null
                      : () => onStatusPressed('overdue'),
                  icon: const Icon(Icons.warning_amber_outlined),
                  label: const Text('Scaduta'),
                ),
                TextButton.icon(
                  onPressed: isUpdating || assignment.isUnpaid
                      ? null
                      : () => onStatusPressed('unpaid'),
                  icon: const Icon(Icons.pending_actions_outlined),
                  label: const Text('Da pagare'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
