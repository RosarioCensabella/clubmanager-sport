import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../callups/domain/callup_summary.dart';
import '../../callups/presentation/callup_providers.dart';
import '../../events/domain/event_summary.dart';
import '../../events/presentation/event_providers.dart';
import '../domain/attendance_summary.dart';
import 'attendance_providers.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  late Future<AppResult<_AttendanceData>> _future;

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<AppResult<_AttendanceData>> _loadData() async {
    final eventRepository = ref.read(eventRepositoryProvider);
    final callupRepository = ref.read(callupRepositoryProvider);
    final attendanceRepository = ref.read(attendanceRepositoryProvider);

    final eventResult = await eventRepository.fetchEventById(
      eventId: widget.eventId,
    );

    switch (eventResult) {
      case AppFailure(:final message, :final code):
        return AppFailure(message, code: code);

      case AppSuccess(:final data):
        final event = data;

        final callupsResult = await callupRepository.fetchCallupsForEvent(
          eventId: widget.eventId,
        );

        switch (callupsResult) {
          case AppFailure(:final message, :final code):
            return AppFailure(message, code: code);

          case AppSuccess(:final data):
            final callups = data;

            final attendanceResult = await attendanceRepository
                .fetchAttendanceForEvent(eventId: widget.eventId);

            switch (attendanceResult) {
              case AppFailure(:final message, :final code):
                return AppFailure(message, code: code);

              case AppSuccess(:final data):
                final attendanceByAthleteId = <String, AttendanceSummary>{};

                for (final attendance in data) {
                  attendanceByAthleteId[attendance.athleteProfileId] =
                      attendance;
                }

                return AppSuccess(
                  _AttendanceData(
                    event: event,
                    callups: callups,
                    attendanceByAthleteId: attendanceByAthleteId,
                  ),
                );
            }
        }
    }
  }

  void _reload() {
    setState(() {
      _future = _loadData();
    });
  }

  Future<void> _updateAttendance({
    required CallupSummary callup,
    required String status,
  }) async {
    if (_isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    final result = await ref
        .read(attendanceRepositoryProvider)
        .updateAttendance(
          eventId: widget.eventId,
          athleteProfileId: callup.athleteProfileId,
          status: status,
          notes: null,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isUpdating = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_successMessageForStatus(status))),
        );
        _reload();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _successMessageForStatus(String status) {
    switch (status) {
      case 'present':
        return 'Presenza registrata.';
      case 'absent':
        return 'Assenza registrata.';
      case 'late':
        return 'Ritardo registrato.';
      case 'excused':
        return 'Assenza giustificata registrata.';
      default:
        return 'Presenza riportata a da registrare.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presenze')),
      body: FutureBuilder<AppResult<_AttendanceData>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(
              message: 'Caricamento registro presenze...',
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
              if (data.callups.isEmpty) {
                return AppEmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'Nessun convocato',
                  message:
                      'Prima di registrare le presenze devi aggiungere almeno un convocato all’evento.',
                  actionLabel: 'Ricarica',
                  onActionPressed: _reload,
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _reload();
                  await _future;
                },
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _EventHeaderCard(event: data.event),
                    const SizedBox(height: 12),
                    _AttendanceSummaryCard(data: data),
                    const SizedBox(height: 12),
                    for (final callup in data.callups) ...[
                      _AttendanceCallupCard(
                        callup: callup,
                        attendance:
                            data.attendanceByAthleteId[callup.athleteProfileId],
                        isUpdating: _isUpdating,
                        onStatusPressed: (status) =>
                            _updateAttendance(callup: callup, status: status),
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

class _AttendanceData {
  const _AttendanceData({
    required this.event,
    required this.callups,
    required this.attendanceByAthleteId,
  });

  final EventSummary event;
  final List<CallupSummary> callups;
  final Map<String, AttendanceSummary> attendanceByAthleteId;

  int countStatus(String status) {
    return callups.where((callup) {
      final attendance = attendanceByAthleteId[callup.athleteProfileId];

      return (attendance?.status ?? 'unknown') == status;
    }).length;
  }
}

class _EventHeaderCard extends StatelessWidget {
  const _EventHeaderCard({required this.event});

  final EventSummary event;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.event_available_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.teamName ?? 'Evento di club',
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

class _AttendanceSummaryCard extends StatelessWidget {
  const _AttendanceSummaryCard({required this.data});

  final _AttendanceData data;

  @override
  Widget build(BuildContext context) {
    final unknown = data.countStatus('unknown');
    final present = data.countStatus('present');
    final absent = data.countStatus('absent');
    final late = data.countStatus('late');
    final excused = data.countStatus('excused');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riepilogo presenze',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text('Convocati: ${data.callups.length}'),
                  avatar: const Icon(Icons.group_outlined, size: 18),
                ),
                Chip(
                  label: Text('Presenti: $present'),
                  avatar: const Icon(Icons.check_circle_outline, size: 18),
                ),
                Chip(
                  label: Text('Assenti: $absent'),
                  avatar: const Icon(Icons.cancel_outlined, size: 18),
                ),
                Chip(
                  label: Text('Ritardi: $late'),
                  avatar: const Icon(Icons.schedule_outlined, size: 18),
                ),
                Chip(
                  label: Text('Giustificati: $excused'),
                  avatar: const Icon(Icons.verified_outlined, size: 18),
                ),
                Chip(
                  label: Text('Da registrare: $unknown'),
                  avatar: const Icon(Icons.pending_actions_outlined, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCallupCard extends StatelessWidget {
  const _AttendanceCallupCard({
    required this.callup,
    required this.attendance,
    required this.isUpdating,
    required this.onStatusPressed,
  });

  final CallupSummary callup;
  final AttendanceSummary? attendance;
  final bool isUpdating;
  final ValueChanged<String> onStatusPressed;

  @override
  Widget build(BuildContext context) {
    final status = attendance?.status ?? 'unknown';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(callup.athlete.initials)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        callup.athlete.fullName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        callup.athlete.teamName ?? 'Nessuna squadra',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF52616B),
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(_statusLabel(status)),
                  avatar: Icon(_statusIcon(status), size: 18),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: isUpdating || status == 'present'
                      ? null
                      : () => onStatusPressed('present'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Presente'),
                ),
                OutlinedButton.icon(
                  onPressed: isUpdating || status == 'absent'
                      ? null
                      : () => onStatusPressed('absent'),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Assente'),
                ),
                OutlinedButton.icon(
                  onPressed: isUpdating || status == 'late'
                      ? null
                      : () => onStatusPressed('late'),
                  icon: const Icon(Icons.schedule_outlined),
                  label: const Text('Ritardo'),
                ),
                OutlinedButton.icon(
                  onPressed: isUpdating || status == 'excused'
                      ? null
                      : () => onStatusPressed('excused'),
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Giustificato'),
                ),
                TextButton.icon(
                  onPressed: isUpdating || status == 'unknown'
                      ? null
                      : () => onStatusPressed('unknown'),
                  icon: const Icon(Icons.pending_actions_outlined),
                  label: const Text('Da registrare'),
                ),
              ],
            ),
            if (attendance?.recordedAt != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Aggiornato il ${_formatDateTime(attendance!.recordedAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF52616B),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'present':
        return 'Presente';
      case 'absent':
        return 'Assente';
      case 'late':
        return 'Ritardo';
      case 'excused':
        return 'Giustificato';
      default:
        return 'Da registrare';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle_outline;
      case 'absent':
        return Icons.cancel_outlined;
      case 'late':
        return Icons.schedule_outlined;
      case 'excused':
        return Icons.verified_outlined;
      default:
        return Icons.pending_actions_outlined;
    }
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString().padLeft(4, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
