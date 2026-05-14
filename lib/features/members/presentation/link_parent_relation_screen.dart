import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  Future<void> _submit() async {
    if (_isLoading) {
      return;
    }

    final clubId = _activeClubId;

    if (clubId == null || clubId.isEmpty) {
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

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Genitore/tutore collegato.')),
        );
        context.pop(true);

      case AppFailure(:final message):
        _showMessage(message);
    }
  }

  Future<void> _pickParent(List<MemberSummary> parents) async {
    final selected = await _showMemberPicker(
      title: 'Seleziona genitore/tutore',
      members: parents,
      selectedUserId: _selectedParentUserId,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedParentUserId = selected.userId;
    });
  }

  Future<void> _pickAthlete(List<AthleteSummary> athletes) async {
    final selected = await _showAthletePicker(
      title: 'Seleziona atleta',
      athletes: athletes,
      selectedAthleteId: _selectedAthleteId,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedAthleteId = selected.id;
    });
  }

  Future<void> _pickRelationType() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        const relationTypes = ['parent', 'mother', 'father', 'guardian'];

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                'Tipo relazione',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              for (final relationType in relationTypes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE0E6ED)),
                    ),
                    leading: const Icon(Icons.family_restroom_outlined),
                    title: Text(_relationLabel(relationType)),
                    trailing: relationType == _relationType
                        ? const Icon(Icons.check_circle)
                        : const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pop(relationType),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _relationType = selected;
    });
  }

  Future<MemberSummary?> _showMemberPicker({
    required String title,
    required List<MemberSummary> members,
    required String? selectedUserId,
  }) async {
    final searchController = TextEditingController();
    var query = '';

    final selected = await showModalBottomSheet<MemberSummary>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = members
                .where((member) {
                  final normalizedQuery = query.trim().toLowerCase();

                  if (normalizedQuery.isEmpty) {
                    return true;
                  }

                  return member.searchableText.contains(normalizedQuery);
                })
                .toList(growable: false);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Cerca',
                          hintText: 'Nome, email...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            query = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('Nessun risultato.'))
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final member = filtered[index];

                                  return ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(
                                        color: Color(0xFFE0E6ED),
                                      ),
                                    ),
                                    leading: CircleAvatar(
                                      child: Text(member.initials),
                                    ),
                                    title: Text(member.fullName),
                                    subtitle: Text(
                                      member.email.isEmpty
                                          ? member.roleLabel
                                          : '${member.email} · ${member.roleLabel}',
                                    ),
                                    trailing: member.userId == selectedUserId
                                        ? const Icon(Icons.check_circle)
                                        : const Icon(Icons.chevron_right),
                                    onTap: () =>
                                        Navigator.of(context).pop(member),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    return selected;
  }

  Future<AthleteSummary?> _showAthletePicker({
    required String title,
    required List<AthleteSummary> athletes,
    required String? selectedAthleteId,
  }) async {
    final searchController = TextEditingController();
    var query = '';

    final selected = await showModalBottomSheet<AthleteSummary>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = athletes
                .where((athlete) {
                  final normalizedQuery = query.trim().toLowerCase();

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

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Cerca atleta',
                          hintText: 'Nome o squadra...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            query = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('Nessun risultato.'))
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final athlete = filtered[index];

                                  return ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(
                                        color: Color(0xFFE0E6ED),
                                      ),
                                    ),
                                    leading: const Icon(
                                      Icons.directions_run_outlined,
                                    ),
                                    title: Text(athlete.fullName),
                                    subtitle: Text(
                                      athlete.teamName ?? 'Nessuna squadra',
                                    ),
                                    trailing: athlete.id == selectedAthleteId
                                        ? const Icon(Icons.check_circle)
                                        : const Icon(Icons.chevron_right),
                                    onTap: () =>
                                        Navigator.of(context).pop(athlete),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    return selected;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

    return '${athlete.fullName} · $teamName';
  }

  String _relationLabel(String relationType) {
    switch (relationType) {
      case 'mother':
        return 'Madre';
      case 'father':
        return 'Padre';
      case 'guardian':
        return 'Tutore';
      default:
        return 'Genitore';
    }
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
              onRetry: () {
                setState(() {
                  _future = _loadData();
                });
              },
            );
          }

          switch (result) {
            case AppFailure(:final message):
              return AppErrorView(
                message: message,
                onRetry: () {
                  setState(() {
                    _future = _loadData();
                  });
                },
              );

            case AppSuccess(:final data):
              final parentCandidates = data.members
                  .where(
                    (member) =>
                        member.hasUserAccount &&
                        !member.isAthleteProfileOnly &&
                        member.role == ClubRole.parent,
                  )
                  .toList(growable: false);

              final selectedParent = _selectedParentFrom(parentCandidates);
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
                      'Cerca un genitore già collegato al club e abbinalo a una scheda atleta.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF52616B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SelectorField(
                      label: 'Genitore/Tutore',
                      value: selectedParent == null
                          ? 'Seleziona genitore/tutore'
                          : selectedParent.fullName,
                      icon: Icons.person_outline,
                      enabled: !_isLoading,
                      onTap: () => _pickParent(parentCandidates),
                    ),
                    const SizedBox(height: 16),
                    _SelectorField(
                      label: 'Atleta',
                      value: selectedAthlete == null
                          ? 'Seleziona atleta'
                          : _athleteLabel(selectedAthlete),
                      icon: Icons.directions_run_outlined,
                      enabled: !_isLoading,
                      onTap: () => _pickAthlete(data.athletes),
                    ),
                    const SizedBox(height: 16),
                    _SelectorField(
                      label: 'Tipo relazione',
                      value: _relationLabel(_relationType),
                      icon: Icons.family_restroom_outlined,
                      enabled: !_isLoading,
                      onTap: _pickRelationType,
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

class _SelectorField extends StatelessWidget {
  const _SelectorField({
    required this.label,
    required this.value,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
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
