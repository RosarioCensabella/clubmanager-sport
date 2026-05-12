import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../domain/athlete_summary.dart';
import 'athlete_providers.dart';

class AthletesScreen extends ConsumerStatefulWidget {
  const AthletesScreen({super.key});

  @override
  ConsumerState<AthletesScreen> createState() => _AthletesScreenState();
}

class _AthletesScreenState extends ConsumerState<AthletesScreen> {
  late Future<AppResult<List<AthleteSummary>>> _future;

  String? _activeClubId;

  @override
  void initState() {
    super.initState();
    _future = _loadAthletes();
  }

  Future<AppResult<List<AthleteSummary>>> _loadAthletes() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final athleteRepository = ref.read(athleteRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return const AppFailure(
        'Seleziona o crea un club prima di gestire gli atleti.',
        code: 'active_club_missing',
      );
    }

    return athleteRepository.fetchAthletesForClub(clubId: _activeClubId!);
  }

  void _reload() {
    setState(() {
      _future = _loadAthletes();
    });
  }

  void _goToCreateAthlete() {
    context.push('/athletes/create').then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atleti'),
        actions: [
          IconButton(
            tooltip: 'Nuovo atleta',
            onPressed: _goToCreateAthlete,
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      body: FutureBuilder<AppResult<List<AthleteSummary>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(message: 'Caricamento atleti...');
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
                  icon: Icons.directions_run_outlined,
                  title: 'Nessun atleta',
                  message:
                      'Aggiungi gli atleti del club e collegali alle squadre.',
                  actionLabel: 'Aggiungi atleta',
                  onActionPressed: _goToCreateAthlete,
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
                    final athlete = data[index];

                    return _AthleteCard(athlete: athlete);
                  },
                ),
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreateAthlete,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Nuovo atleta'),
      ),
    );
  }
}

class _AthleteCard extends StatelessWidget {
  const _AthleteCard({required this.athlete});

  final AthleteSummary athlete;

  @override
  Widget build(BuildContext context) {
    final certificateColor = _certificateColor();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Collegamento genitori/tutori disponibile nella prossima sotto-fase.',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                child: Text(athlete.initials),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      athlete.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildSubtitle(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF52616B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (athlete.teamName != null &&
                            athlete.teamName!.isNotEmpty)
                          Chip(
                            label: Text(athlete.teamName!),
                            avatar: const Icon(
                              Icons.groups_2_outlined,
                              size: 18,
                            ),
                          ),
                        Chip(
                          label: Text(athlete.medicalCertificateStatusLabel),
                          avatar: Icon(
                            Icons.medical_information_outlined,
                            color: certificateColor,
                            size: 18,
                          ),
                        ),
                        if (athlete.medicalCertificateExpiry != null)
                          Chip(
                            label: Text(
                              _formatDate(athlete.medicalCertificateExpiry!),
                            ),
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
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];

    if (athlete.jerseyNumber != null && athlete.jerseyNumber!.isNotEmpty) {
      parts.add('N. ${athlete.jerseyNumber}');
    }

    if (athlete.sportRole != null && athlete.sportRole!.isNotEmpty) {
      parts.add(athlete.sportRole!);
    }

    if (athlete.dateOfBirth != null) {
      parts.add('Nato/a il ${_formatDate(athlete.dateOfBirth!)}');
    }

    if (parts.isEmpty) {
      return 'Atleta del club';
    }

    return parts.join(' · ');
  }

  Color _certificateColor() {
    switch (athlete.medicalCertificateStatus) {
      case 'valid':
        return const Color(0xFF2E7D32);
      case 'expiring':
        return const Color(0xFFF9A825);
      case 'expired':
      case 'rejected':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');

    return '$day/$month/$year';
  }
}
