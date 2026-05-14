import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/permissions/club_role.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../athletes/domain/athlete_summary.dart';
import '../../athletes/presentation/athlete_providers.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../../teams/domain/team_summary.dart';
import '../../teams/presentation/team_providers.dart';
import '../domain/create_invitation_request.dart';
import 'invitation_providers.dart';

class CreateInvitationScreen extends ConsumerStatefulWidget {
  const CreateInvitationScreen({super.key});

  @override
  ConsumerState<CreateInvitationScreen> createState() =>
      _CreateInvitationScreenState();
}

class _CreateInvitationScreenState
    extends ConsumerState<CreateInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  ClubRole _role = ClubRole.parent;
  String? _selectedTeamId;
  String? _selectedAthleteProfileId;
  bool _isLoading = false;

  Future<_InvitationReferenceData>? _referenceFuture;
  String? _activeClubId;

  @override
  void initState() {
    super.initState();
    _referenceFuture = _loadReferenceData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<_InvitationReferenceData> _loadReferenceData() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final teamRepository = ref.read(teamRepositoryProvider);
    final athleteRepository = ref.read(athleteRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return const _InvitationReferenceData(teams: [], athletes: []);
    }

    final teamsResult = await teamRepository.fetchTeamsForClub(
      clubId: _activeClubId!,
    );

    final athletesResult = await athleteRepository.fetchAthletesForClub(
      clubId: _activeClubId!,
    );

    final teams = switch (teamsResult) {
      AppSuccess(:final data) => data,
      AppFailure() => <TeamSummary>[],
    };

    final athletes = switch (athletesResult) {
      AppSuccess(:final data) => data,
      AppFailure() => <AthleteSummary>[],
    };

    return _InvitationReferenceData(teams: teams, athletes: athletes);
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    final clubId =
        _activeClubId ??
        await ref.read(clubContextRepositoryProvider).getActiveClubId();

    if (!mounted) {
      return;
    }

    if (clubId == null || clubId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona o crea un club prima di invitare utenti.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final invitationRepository = ref.read(invitationRepositoryProvider);
    final token = invitationRepository.generateInvitationToken();

    final request = CreateInvitationRequest(
      clubId: clubId,
      teamId: _selectedTeamId,
      athleteProfileId: _selectedAthleteProfileId,
      email: _emailController.text,
      role: _role,
      token: token,
      expiresAt: DateTime.now().add(const Duration(days: 14)),
    );

    final createResult = await invitationRepository.createInvitation(request);

    if (!mounted) {
      return;
    }

    switch (createResult) {
      case AppFailure(:final message):
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));

      case AppSuccess(data: final invitationId):
        final emailResult = await invitationRepository.sendInvitationEmail(
          invitationId: invitationId,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
        });

        switch (emailResult) {
          case AppSuccess():
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invito creato ed email inviata.')),
            );

          case AppFailure(:final message):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invito creato, ma email non inviata: $message'),
              ),
            );
        }

        context.pop();
    }
  }

  bool get _shouldShowTeamSelector {
    return _role == ClubRole.coach ||
        _role == ClubRole.teamManager ||
        _role == ClubRole.staff;
  }

  bool get _shouldShowAthleteSelector {
    return _role == ClubRole.athlete || _role == ClubRole.parent;
  }

  void _onRoleChanged(ClubRole role) {
    setState(() {
      _role = role;

      if (!_shouldShowTeamSelectorFor(role)) {
        _selectedTeamId = null;
      }

      if (!_shouldShowAthleteSelectorFor(role)) {
        _selectedAthleteProfileId = null;
      }
    });
  }

  bool _shouldShowTeamSelectorFor(ClubRole role) {
    return role == ClubRole.coach ||
        role == ClubRole.teamManager ||
        role == ClubRole.staff;
  }

  bool _shouldShowAthleteSelectorFor(ClubRole role) {
    return role == ClubRole.athlete || role == ClubRole.parent;
  }

  void _onAthleteSelected(AthleteSummary? athlete) {
    setState(() {
      _selectedAthleteProfileId = athlete?.id;

      if (_role == ClubRole.athlete && athlete?.teamId != null) {
        _selectedTeamId = athlete!.teamId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo invito')),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: FutureBuilder<_InvitationReferenceData>(
            future: _referenceFuture,
            builder: (context, snapshot) {
              final referenceData =
                  snapshot.data ??
                  const _InvitationReferenceData(teams: [], athletes: []);

              return ListView(
                children: [
                  Text(
                    'Invita un utente',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Per atleti e genitori puoi collegare direttamente la scheda atleta: così l’account avrà subito il contesto corretto.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF52616B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email invitato',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      final email = value ?? '';

                      if (email.isBlank) {
                        return 'Inserisci l’email dell’invitato.';
                      }

                      if (!email.isValidEmail) {
                        return 'Inserisci un indirizzo email valido.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ClubRole>(
                    initialValue: _role,
                    decoration: const InputDecoration(
                      labelText: 'Ruolo',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ClubRole.admin,
                        child: Text('Admin club'),
                      ),
                      DropdownMenuItem(
                        value: ClubRole.teamManager,
                        child: Text('Manager squadra'),
                      ),
                      DropdownMenuItem(
                        value: ClubRole.coach,
                        child: Text('Allenatore'),
                      ),
                      DropdownMenuItem(
                        value: ClubRole.parent,
                        child: Text('Genitore/Tutore'),
                      ),
                      DropdownMenuItem(
                        value: ClubRole.athlete,
                        child: Text('Atleta'),
                      ),
                      DropdownMenuItem(
                        value: ClubRole.staff,
                        child: Text('Staff'),
                      ),
                    ],
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }

                            _onRoleChanged(value);
                          },
                  ),
                  const SizedBox(height: 16),
                  if (_shouldShowAthleteSelector)
                    _AthleteSelector(
                      athletes: referenceData.athletes,
                      selectedAthleteProfileId: _selectedAthleteProfileId,
                      role: _role,
                      isLoading: _isLoading,
                      onChanged: _onAthleteSelected,
                    ),
                  if (_shouldShowAthleteSelector) const SizedBox(height: 16),
                  if (_shouldShowTeamSelector)
                    _TeamSelector(
                      teams: referenceData.teams,
                      selectedTeamId: _selectedTeamId,
                      isLoading: _isLoading,
                      onChanged: (teamId) {
                        setState(() {
                          _selectedTeamId = teamId;
                        });
                      },
                    ),
                  const SizedBox(height: 28),
                  AppPrimaryButton(
                    label: 'Crea e invia invito',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InvitationReferenceData {
  const _InvitationReferenceData({required this.teams, required this.athletes});

  final List<TeamSummary> teams;
  final List<AthleteSummary> athletes;
}

class _AthleteSelector extends StatelessWidget {
  const _AthleteSelector({
    required this.athletes,
    required this.selectedAthleteProfileId,
    required this.role,
    required this.isLoading,
    required this.onChanged,
  });

  final List<AthleteSummary> athletes;
  final String? selectedAthleteProfileId;
  final ClubRole role;
  final bool isLoading;
  final ValueChanged<AthleteSummary?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: selectedAthleteProfileId,
      decoration: InputDecoration(
        labelText: role == ClubRole.athlete
            ? 'Scheda atleta da collegare'
            : 'Atleta figlio/tutelato',
        helperText: role == ClubRole.athlete
            ? 'Obbligatorio per collegare l’account alla scheda atleta.'
            : 'Opzionale, ma consigliato per collegare subito il genitore.',
        prefixIcon: const Icon(Icons.directions_run_outlined),
      ),
      items: [
        if (role != ClubRole.athlete)
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Nessun atleta collegato ora'),
          ),
        for (final athlete in athletes)
          DropdownMenuItem<String?>(
            value: athlete.id,
            child: Text(_athleteLabel(athlete)),
          ),
      ],
      validator: (value) {
        if (role == ClubRole.athlete && (value == null || value.isEmpty)) {
          return 'Seleziona la scheda atleta da collegare.';
        }

        return null;
      },
      onChanged: isLoading
          ? null
          : (value) {
              final matches = athletes.where((athlete) => athlete.id == value);

              onChanged(matches.isEmpty ? null : matches.first);
            },
    );
  }

  static String _athleteLabel(AthleteSummary athlete) {
    final teamName = athlete.teamName;

    if (teamName == null || teamName.trim().isEmpty) {
      return athlete.fullName;
    }

    return '${athlete.fullName} · $teamName';
  }
}

class _TeamSelector extends StatelessWidget {
  const _TeamSelector({
    required this.teams,
    required this.selectedTeamId,
    required this.isLoading,
    required this.onChanged,
  });

  final List<TeamSummary> teams;
  final String? selectedTeamId;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: selectedTeamId,
      decoration: const InputDecoration(
        labelText: 'Squadra',
        helperText: 'Consigliata per coach, staff e manager squadra.',
        prefixIcon: Icon(Icons.groups_2_outlined),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Nessuna squadra'),
        ),
        for (final team in teams)
          DropdownMenuItem<String?>(value: team.id, child: Text(team.name)),
      ],
      onChanged: isLoading ? null : onChanged,
    );
  }
}
