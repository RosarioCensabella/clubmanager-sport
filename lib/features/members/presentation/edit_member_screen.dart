import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/permissions/club_role.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../data/member_admin_repository.dart';
import '../domain/member_summary.dart';
import 'member_providers.dart';

class EditMemberScreen extends ConsumerStatefulWidget {
  const EditMemberScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends ConsumerState<EditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  final _adminRepository = MemberAdminRepository();

  late Future<AppResult<MemberSummary>> _future;

  String? _activeClubId;
  ClubRole _selectedRole = ClubRole.staff;
  String _selectedStatus = 'active';
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _future = _loadMember();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<AppResult<MemberSummary>> _loadMember() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final memberRepository = ref.read(memberRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return const AppFailure(
        'Seleziona o crea un club prima di modificare persone e accessi.',
        code: 'active_club_missing',
      );
    }

    final result = await memberRepository.fetchMembersForClub(
      clubId: _activeClubId!,
    );

    switch (result) {
      case AppFailure(:final message, :final code):
        return AppFailure(message, code: code);

      case AppSuccess(:final data):
        final matches = data.where(
          (member) =>
              member.userId == widget.userId &&
              member.hasUserAccount &&
              !member.isAthleteProfileOnly,
        );

        if (matches.isEmpty) {
          return const AppFailure(
            'Persona non trovata o non modificabile.',
            code: 'member_not_found',
          );
        }

        final member = matches.first;

        if (!_initialized) {
          _firstNameController.text = member.firstName ?? '';
          _lastNameController.text = member.lastName ?? '';
          _selectedRole = member.role == ClubRole.unknown
              ? ClubRole.staff
              : member.role;
          _selectedStatus = _normalizeStatus(member.status);
          _initialized = true;
        }

        return AppSuccess(member);
    }
  }

  void _reload() {
    setState(() {
      _initialized = false;
      _future = _loadMember();
    });
  }

  String _normalizeStatus(String status) {
    switch (status) {
      case 'active':
      case 'pending':
      case 'suspended':
      case 'removed':
        return status;
      default:
        return 'active';
    }
  }

  Future<void> _save(MemberSummary member) async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    final clubId = _activeClubId;

    if (clubId == null || clubId.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _adminRepository.updateMember(
      clubId: clubId,
      userId: member.userId,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      role: _selectedRole,
      status: _selectedStatus,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Persona aggiornata.')));
        Navigator.of(context).pop(true);

      case AppFailure(:final message):
        _showMessage(message);
    }
  }

  Future<void> _removeTeamAssignment(MemberTeamAssignment assignment) async {
    final confirmed = await _confirm(
      title: 'Rimuovere assegnazione?',
      message:
          'Vuoi rimuovere ${assignment.roleLabel} dalla squadra ${assignment.teamName}?',
      actionLabel: 'Rimuovi',
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _adminRepository.removeTeamAssignment(
      assignmentId: assignment.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AppSuccess():
        _showMessage('Assegnazione squadra rimossa.');
        _reload();

      case AppFailure(:final message):
        _showMessage(message);
    }
  }

  Future<void> _removeParentRelation(MemberParentRelation relation) async {
    final confirmed = await _confirm(
      title: 'Rimuovere collegamento?',
      message:
          'Vuoi rimuovere il collegamento con ${relation.athleteName} (${relation.relationLabel})?',
      actionLabel: 'Rimuovi',
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _adminRepository.removeParentRelation(
      relationId: relation.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AppSuccess():
        _showMessage('Collegamento genitore-atleta rimosso.');
        _reload();

      case AppFailure(:final message):
        _showMessage(message);
    }
  }

  Future<void> _unlinkAthleteAccount(
    MemberSummary member,
    MemberAthleteProfile athleteProfile,
  ) async {
    final confirmed = await _confirm(
      title: 'Scollegare account atleta?',
      message:
          'Vuoi scollegare l’account di ${member.fullName} dalla scheda ${athleteProfile.athleteName}?',
      actionLabel: 'Scollega',
    );

    if (confirmed != true) {
      return;
    }

    final clubId = _activeClubId;

    if (clubId == null || clubId.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _adminRepository.unlinkAthleteAccount(
      clubId: clubId,
      athleteId: athleteProfile.athleteId,
      userId: member.userId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AppSuccess():
        _showMessage('Account atleta scollegato.');
        _reload();

      case AppFailure(:final message):
        _showMessage(message);
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String actionLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifica persona')),
      body: FutureBuilder<AppResult<MemberSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(message: 'Caricamento persona...');
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
              final member = data;
              final isOwner = member.role == ClubRole.owner;

              return SafeArea(
                minimum: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      _HeaderCard(member: member),
                      const SizedBox(height: 12),
                      _ProfileFormCard(
                        firstNameController: _firstNameController,
                        lastNameController: _lastNameController,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 12),
                      _RoleStatusCard(
                        selectedRole: _selectedRole,
                        selectedStatus: _selectedStatus,
                        isOwner: isOwner,
                        isLoading: _isLoading,
                        onRoleChanged: (role) {
                          setState(() {
                            _selectedRole = role;
                          });
                        },
                        onStatusChanged: (status) {
                          setState(() {
                            _selectedStatus = status;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _TeamAssignmentsCard(
                        assignments: member.teamAssignments,
                        isLoading: _isLoading,
                        onRemove: _removeTeamAssignment,
                      ),
                      const SizedBox(height: 12),
                      _ParentRelationsCard(
                        relations: member.parentRelations,
                        isLoading: _isLoading,
                        onRemove: _removeParentRelation,
                      ),
                      const SizedBox(height: 12),
                      _AthleteProfilesCard(
                        member: member,
                        profiles: member.athleteProfiles,
                        isLoading: _isLoading,
                        onUnlink: (profile) =>
                            _unlinkAthleteAccount(member, profile),
                      ),
                      const SizedBox(height: 24),
                      AppPrimaryButton(
                        label: 'Salva modifiche',
                        isLoading: _isLoading,
                        onPressed: () => _save(member),
                      ),
                    ],
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.member});

  final MemberSummary member;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              child: Text(member.initials),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    member.email.isEmpty
                        ? 'Email non disponibile'
                        : member.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF52616B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.badge_outlined, size: 18),
                        label: Text(member.roleLabel),
                      ),
                      Chip(
                        avatar: const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                        ),
                        label: Text(member.statusLabel),
                      ),
                    ],
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

class _ProfileFormCard extends StatelessWidget {
  const _ProfileFormCard({
    required this.firstNameController,
    required this.lastNameController,
    required this.isLoading,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dati profilo',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: firstNameController,
              enabled: !isLoading,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                final firstName = value ?? '';

                if (firstName.isBlank) {
                  return 'Inserisci il nome.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: lastNameController,
              enabled: !isLoading,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Cognome',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                final lastName = value ?? '';

                if (lastName.isBlank) {
                  return 'Inserisci il cognome.';
                }

                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleStatusCard extends StatelessWidget {
  const _RoleStatusCard({
    required this.selectedRole,
    required this.selectedStatus,
    required this.isOwner,
    required this.isLoading,
    required this.onRoleChanged,
    required this.onStatusChanged,
  });

  final ClubRole selectedRole;
  final String selectedStatus;
  final bool isOwner;
  final bool isLoading;
  final ValueChanged<ClubRole> onRoleChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final roles = [
      ClubRole.admin,
      ClubRole.teamManager,
      ClubRole.coach,
      ClubRole.staff,
      ClubRole.athlete,
      ClubRole.parent,
      if (isOwner) ClubRole.owner,
    ];

    const statuses = [
      _StatusOption(value: 'active', label: 'Attivo'),
      _StatusOption(value: 'pending', label: 'In attesa'),
      _StatusOption(value: 'suspended', label: 'Sospeso'),
      _StatusOption(value: 'removed', label: 'Rimosso'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ruolo e accesso',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              isOwner
                  ? 'Il proprietario non può essere declassato da questa schermata.'
                  : 'Modifica il ruolo generale nel club e lo stato di accesso.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF52616B)),
            ),
            const SizedBox(height: 16),
            Text(
              'Ruolo nel club',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final role in roles)
                  ChoiceChip(
                    label: Text(role.label),
                    selected: selectedRole == role,
                    onSelected: isLoading || isOwner
                        ? null
                        : (_) => onRoleChanged(role),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Stato accesso',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in statuses)
                  ChoiceChip(
                    label: Text(status.label),
                    selected: selectedStatus == status.value,
                    onSelected: isLoading || isOwner
                        ? null
                        : (_) => onStatusChanged(status.value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamAssignmentsCard extends StatelessWidget {
  const _TeamAssignmentsCard({
    required this.assignments,
    required this.isLoading,
    required this.onRemove,
  });

  final List<MemberTeamAssignment> assignments;
  final bool isLoading;
  final ValueChanged<MemberTeamAssignment> onRemove;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Squadre assegnate',
      emptyMessage: 'Nessuna squadra assegnata.',
      children: [
        for (final assignment in assignments)
          _ActionListTile(
            icon: Icons.groups_2_outlined,
            title: assignment.teamName,
            subtitle: assignment.roleLabel,
            actionLabel: assignment.id.startsWith('athlete-team')
                ? 'Da scheda atleta'
                : 'Rimuovi',
            actionIcon: assignment.id.startsWith('athlete-team')
                ? Icons.lock_outline
                : Icons.remove_circle_outline,
            enabled: !isLoading && !assignment.id.startsWith('athlete-team'),
            onPressed: () => onRemove(assignment),
          ),
      ],
    );
  }
}

class _ParentRelationsCard extends StatelessWidget {
  const _ParentRelationsCard({
    required this.relations,
    required this.isLoading,
    required this.onRemove,
  });

  final List<MemberParentRelation> relations;
  final bool isLoading;
  final ValueChanged<MemberParentRelation> onRemove;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Atleti collegati come genitore/tutore',
      emptyMessage: 'Nessun atleta collegato.',
      children: [
        for (final relation in relations)
          _ActionListTile(
            icon: Icons.family_restroom_outlined,
            title: relation.athleteName,
            subtitle: relation.relationLabel,
            actionLabel: 'Rimuovi',
            actionIcon: Icons.remove_circle_outline,
            enabled: !isLoading,
            onPressed: () => onRemove(relation),
          ),
      ],
    );
  }
}

class _AthleteProfilesCard extends StatelessWidget {
  const _AthleteProfilesCard({
    required this.member,
    required this.profiles,
    required this.isLoading,
    required this.onUnlink,
  });

  final MemberSummary member;
  final List<MemberAthleteProfile> profiles;
  final bool isLoading;
  final ValueChanged<MemberAthleteProfile> onUnlink;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Schede atleta collegate',
      emptyMessage: 'Nessuna scheda atleta collegata.',
      children: [
        for (final profile in profiles)
          _ActionListTile(
            icon: Icons.directions_run_outlined,
            title: profile.athleteName,
            subtitle: profile.teamName ?? 'Nessuna squadra',
            actionLabel: 'Scollega',
            actionIcon: Icons.link_off_outlined,
            enabled: !isLoading && member.hasUserAccount,
            onPressed: () => onUnlink(profile),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.emptyMessage,
    required this.children,
  });

  final String title;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (children.isEmpty)
              Text(
                emptyMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF52616B),
                ),
              )
            else
              ...children,
          ],
        ),
      ),
    );
  }
}

class _ActionListTile extends StatelessWidget {
  const _ActionListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionIcon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData actionIcon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0E6ED)),
        ),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: TextButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: Icon(actionIcon),
          label: Text(actionLabel),
        ),
      ),
    );
  }
}

class _StatusOption {
  const _StatusOption({required this.value, required this.label});

  final String value;
  final String label;
}
