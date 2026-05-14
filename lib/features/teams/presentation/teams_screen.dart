import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../domain/team_summary.dart';
import 'team_providers.dart';

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  late Future<AppResult<List<TeamSummary>>> _future;

  String? _activeClubId;

  @override
  void initState() {
    super.initState();
    _future = _loadTeams();
  }

  Future<AppResult<List<TeamSummary>>> _loadTeams() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final teamRepository = ref.read(teamRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return const AppFailure(
        'Seleziona o crea un club prima di gestire le squadre.',
        code: 'active_club_missing',
      );
    }

    return teamRepository.fetchTeamsForClub(clubId: _activeClubId!);
  }

  void _reload() {
    setState(() {
      _future = _loadTeams();
    });
  }

  void _goToCreateTeam() {
    context.push('/teams/create').then((_) => _reload());
  }

  void _goToTeamDetail(TeamSummary team) {
    context.push('/teams/${team.id}').then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Squadre'),
        actions: [
          IconButton(
            tooltip: 'Nuova squadra',
            onPressed: _goToCreateTeam,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<AppResult<List<TeamSummary>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(message: 'Caricamento squadre...');
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
                  icon: Icons.groups_2_outlined,
                  title: 'Nessuna squadra',
                  message:
                      'Crea la prima squadra del club per iniziare a gestire atleti, allenamenti e convocazioni.',
                  actionLabel: 'Crea squadra',
                  onActionPressed: _goToCreateTeam,
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
                    final team = data[index];

                    return _TeamCard(
                      team: team,
                      onTap: () => _goToTeamDetail(team),
                    );
                  },
                ),
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreateTeam,
        icon: const Icon(Icons.add),
        label: const Text('Nuova squadra'),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team, required this.onTap});

  final TeamSummary team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                child: Text(_firstLetter(team.name)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
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
                        Chip(
                          label: Text(team.sport),
                          avatar: const Icon(Icons.sports_soccer, size: 18),
                        ),
                        Chip(
                          label: Text(team.genderLabel),
                          avatar: const Icon(Icons.people_outline, size: 18),
                        ),
                        if (team.season != null && team.season!.isNotEmpty)
                          Chip(
                            label: Text(team.season!),
                            avatar: const Icon(
                              Icons.calendar_month_outlined,
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

  String _buildSubtitle() {
    final parts = <String>[];

    if (team.category != null && team.category!.isNotEmpty) {
      parts.add(team.category!);
    }

    if (team.birthYear != null) {
      parts.add('Anno ${team.birthYear}');
    }

    if (team.trainingLocation != null && team.trainingLocation!.isNotEmpty) {
      parts.add(team.trainingLocation!);
    }

    if (parts.isEmpty) {
      return 'Squadra del club';
    }

    return parts.join(' · ');
  }

  String _firstLetter(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return '?';
    }

    return trimmed.substring(0, 1).toUpperCase();
  }
}
