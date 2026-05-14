import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/permissions/club_role.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_primary_button.dart';
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
  bool _isLoading = false;

  Future<List<TeamSummary>>? _teamsFuture;
  String? _activeClubId;

  @override
  void initState() {
    super.initState();
    _teamsFuture = _loadTeams();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<List<TeamSummary>> _loadTeams() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final teamRepository = ref.read(teamRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return [];
    }

    final result = await teamRepository.fetchTeamsForClub(
      clubId: _activeClubId!,
    );

    switch (result) {
      case AppSuccess(:final data):
        return data;
      case AppFailure():
        return [];
    }
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
        _role == ClubRole.athlete ||
        _role == ClubRole.parent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo invito')),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Invita un utente',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea un invito con ruolo assegnato. L’email verrà inviata automaticamente se il provider email è configurato.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF52616B)),
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
                  DropdownMenuItem(value: ClubRole.staff, child: Text('Staff')),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _role = value;

                          if (!_shouldShowTeamSelector) {
                            _selectedTeamId = null;
                          }
                        });
                      },
              ),
              const SizedBox(height: 16),
              if (_shouldShowTeamSelector)
                FutureBuilder<List<TeamSummary>>(
                  future: _teamsFuture,
                  builder: (context, snapshot) {
                    final teams = snapshot.data ?? [];

                    return DropdownButtonFormField<String?>(
                      initialValue: _selectedTeamId,
                      decoration: const InputDecoration(
                        labelText: 'Squadra',
                        helperText: 'Opzionale.',
                        prefixIcon: Icon(Icons.groups_2_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Nessuna squadra'),
                        ),
                        for (final team in teams)
                          DropdownMenuItem<String?>(
                            value: team.id,
                            child: Text(team.name),
                          ),
                      ],
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _selectedTeamId = value;
                              });
                            },
                    );
                  },
                ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: 'Crea e invia invito',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
