import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions/club_role.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../athletes/domain/athlete_summary.dart';
import '../../athletes/presentation/athlete_providers.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../domain/member_summary.dart';
import 'member_providers.dart';

class LinkParentRelationScreen extends ConsumerStatefulWidget {
  const LinkParentRelationScreen({super.key});

  @override
  ConsumerState<LinkParentRelationScreen> createState() =>
      _LinkParentRelationScreenState();
}

class _LinkParentRelationScreenState
    extends ConsumerState<LinkParentRelationScreen> {
  late Future<AppResult<_LinkParentRelationData>> _future;

  String? _activeClubId;
  String? _selectedParentUserId;
  String? _selectedAthleteId;
  String _parentQuery = '';
  String _athleteQuery = '';
  String _relationType = 'parent';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<AppResult<_LinkParentRelationData>> _loadData() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final memberRepository = ref.read(memberRepositoryProvider);
    final athleteRepository = ref.read(athleteRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return const AppFailure(
        'Seleziona un club prima di collegare genitori e atleti.',
        code: 'active_club_missing',
      );
    }

    final membersResult = await memberRepository.fetchMembersForClub(
      clubId: _activeClubId!,
    );

    final athletesResult = await athleteRepository.fetchAthletesForClub(
      clubId: _activeClubId!,
    );

    switch (membersResult) {
      case AppFailure(:final message, :final code):
        return AppFailure(message, code: code);

      case AppSuccess(:final data):
        final members = data;

        switch (athletesResult) {
          case AppFailure(:final message, :final code):
            return AppFailure(message, code: code);

          case AppSuccess(:final data):
            return AppSuccess(
              _LinkParentRelationData(members: members, athletes: data),
            );
        }
    }
  }

  void _reload() {
    setState(() {
      _future = _loadData();
    });
  }

  Future<void> _submit() async {
    if (_isLoading) {
      return;
    }

    final clubId = _activeClubId;

    if (clubId == null || clubId.isEmpty) {
      _showMessage('Club attivo non valido.');
      return;
    }

    if (_selectedParentUserId == null || _selectedParentUserId!.isEmpty) {
      _showMessage('Seleziona un genitore/tutore.');
      return;
    }

    if (_selectedAthleteId == null || _selectedAthleteId!.isEmpty) {
      _showMessage('Seleziona un atleta.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ref
        .read(memberRepositoryProvider)
        .linkParentToAthlete(
          clubId: clubId,
          parentUserId: _selectedParentUserId!,
          athleteId: _selectedAthleteId!,
          relationType: _relationType,
        );

    if (!mounted) {
      return;
    }

    switch (result) {
      case AppSuccess():
        Navigator.of(context).pop(true);

      case AppFailure(:final message):
        setState(() {
          _isLoading = false;
        });

        _showMessage(message);
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<MemberSummary> _parentCandidates(List<MemberSummary> members) {
    final normalizedQuery = _parentQuery.trim().toLowerCase();

    return members
        .where((member) => member.userId.trim().isNotEmpty)
        .where((member) => member.role == ClubRole.parent)
        .where((member) {
          if (normalizedQuery.isEmpty) {
            return true;
          }

          return member.searchableText.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  List<AthleteSummary> _filteredAthletes(List<AthleteSummary> athletes) {
    final normalizedQuery = _athleteQuery.trim().toLowerCase();

    return athletes
        .where((athlete) {
          if (normalizedQuery.isEmpty) {
            return true;
          }

          return [
            athlete.fullName,
            athlete.teamName ?? '',
            athlete.sportRole ?? '',
          ].join(' ').toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  MemberSummary? _selectedParentFrom(List<MemberSummary> members) {
    for (final member in members) {
      if (member.userId == _selectedParentUserId) {
        return member;
      }
    }

    return null;
  }

  AthleteSummary? _selectedAthleteFrom(List<AthleteSummary> athletes) {
    for (final athlete in athletes) {
      if (athlete.id == _selectedAthleteId) {
        return athlete;
      }
    }

    return null;
  }

  String _athleteLabel(AthleteSummary athlete) {
    final teamName = athlete.teamName;

    if (teamName == null || teamName.trim().isEmpty) {
      return athlete.fullName;
    }

    return '${athlete.fullName} Â· $teamName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collega genitore')),
      body: FutureBuilder<AppResult<_LinkParentRelationData>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(message: 'Caricamento dati...');
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
              final visibleParents = _parentCandidates(data.members);
              final visibleAthletes = _filteredAthletes(data.athletes);
              final selectedParent = _selectedParentFrom(data.members);
              final selectedAthlete = _selectedAthleteFrom(data.athletes);

              return SafeArea(
                minimum: const EdgeInsets.all(24),
                child: ListView(
                  children: [
                    Text(
                      'Collega genitore/tutore ad atleta',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cerca un genitore giÃ  collegato al club e abbinalo a una scheda atleta.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF52616B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (selectedParent != null)
                      _SelectedValueCard(
                        icon: Icons.person_outline,
                        title: 'Genitore selezionato',
                        value: selectedParent.fullName,
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Cerca genitore/tutore',
                        hintText: 'Nome o email...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _parentQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _SectionTitle(title: 'Genitori disponibili'),
                    const SizedBox(height: 8),
                    if (visibleParents.isEmpty)
                      const _EmptyInlineMessage(
                        message:
                            'Nessun genitore/tutore trovato. Invitalo prima come Genitore/Tutore.',
                      )
                    else
                      for (final parent in visibleParents) ...[
                        _SelectableParentTile(
                          member: parent,
                          selected: parent.userId == _selectedParentUserId,
                          enabled: !_isLoading,
                          onTap: () {
                            setState(() {
                              _selectedParentUserId = parent.userId;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 16),
                    if (selectedAthlete != null)
                      _SelectedValueCard(
                        icon: Icons.directions_run_outlined,
                        title: 'Atleta selezionato',
                        value: _athleteLabel(selectedAthlete),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Cerca atleta',
                        hintText: 'Nome o squadra...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _athleteQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _SectionTitle(title: 'Atleti disponibili'),
                    const SizedBox(height: 8),
                    if (visibleAthletes.isEmpty)
                      const _EmptyInlineMessage(
                        message: 'Nessun atleta trovato.',
                      )
                    else
                      for (final athlete in visibleAthletes) ...[
                        _SelectableAthleteTile(
                          athlete: athlete,
                          selected: athlete.id == _selectedAthleteId,
                          enabled: !_isLoading,
                          label: _athleteLabel(athlete),
                          onTap: () {
                            setState(() {
                              _selectedAthleteId = athlete.id;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 16),
                    _SectionTitle(title: 'Tipo relazione'),
                    const SizedBox(height: 8),
                    _RelationTypePicker(
                      selectedRelationType: _relationType,
                      enabled: !_isLoading,
                      onChanged: (value) {
                        setState(() {
                          _relationType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 28),
                    AppPrimaryButton(
                      label: 'Collega',
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}

class _LinkParentRelationData {
  const _LinkParentRelationData({
    required this.members,
    required this.athletes,
  });

  final List<MemberSummary> members;
  final List<AthleteSummary> athletes;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _SelectedValueCard extends StatelessWidget {
  const _SelectedValueCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
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

class _SelectableParentTile extends StatelessWidget {
  const _SelectableParentTile({
    required this.member,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final MemberSummary member;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableTile(
      selected: selected,
      enabled: enabled,
      icon: Icons.person_outline,
      title: member.fullName,
      subtitle: member.email.isEmpty
          ? member.roleLabel
          : '${member.email} Â· ${member.roleLabel}',
      onTap: onTap,
    );
  }
}

class _SelectableAthleteTile extends StatelessWidget {
  const _SelectableAthleteTile({
    required this.athlete,
    required this.selected,
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final AthleteSummary athlete;
  final bool selected;
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableTile(
      selected: selected,
      enabled: enabled,
      icon: Icons.directions_run_outlined,
      title: athlete.fullName,
      subtitle: label,
      onTap: onTap,
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFFE0E6ED),
          width: selected ? 2 : 1,
        ),
      ),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected
          ? const Icon(Icons.check_circle)
          : const Icon(Icons.chevron_right),
      onTap: enabled ? onTap : null,
    );
  }
}

class _RelationTypePicker extends StatelessWidget {
  const _RelationTypePicker({
    required this.selectedRelationType,
    required this.enabled,
    required this.onChanged,
  });

  final String selectedRelationType;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      _RelationTypeOption(value: 'parent', label: 'Genitore'),
      _RelationTypeOption(value: 'mother', label: 'Madre'),
      _RelationTypeOption(value: 'father', label: 'Padre'),
      _RelationTypeOption(value: 'guardian', label: 'Tutore'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(option.label),
            selected: selectedRelationType == option.value,
            onSelected: enabled ? (_) => onChanged(option.value) : null,
          ),
      ],
    );
  }
}

class _RelationTypeOption {
  const _RelationTypeOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _EmptyInlineMessage extends StatelessWidget {
  const _EmptyInlineMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF52616B)),
        ),
      ),
    );
  }
}
