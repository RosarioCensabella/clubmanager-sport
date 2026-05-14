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

class LinkAthleteAccountScreen extends ConsumerStatefulWidget {
  const LinkAthleteAccountScreen({super.key});

  @override
  ConsumerState<LinkAthleteAccountScreen> createState() =>
      _LinkAthleteAccountScreenState();
}

class _LinkAthleteAccountScreenState
    extends ConsumerState<LinkAthleteAccountScreen> {
  late Future<AppResult<_LinkAthleteAccountData>> _future;

  String? _activeClubId;
  String? _selectedAthleteUserId;
  String? _selectedAthleteId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<AppResult<_LinkAthleteAccountData>> _loadData() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final memberRepository = ref.read(memberRepositoryProvider);
    final athleteRepository = ref.read(athleteRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return const AppFailure(
        'Seleziona un club prima di collegare account atleta.',
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
              _LinkAthleteAccountData(members: members, athletes: data),
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

    if (_selectedAthleteUserId == null || _selectedAthleteUserId!.isEmpty) {
      _showMessage('Seleziona un account atleta.');
      return;
    }

    if (_selectedAthleteId == null || _selectedAthleteId!.isEmpty) {
      _showMessage('Seleziona una scheda atleta.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ref
        .read(memberRepositoryProvider)
        .linkAthleteAccount(
          clubId: clubId,
          athleteUserId: _selectedAthleteUserId!,
          athleteId: _selectedAthleteId!,
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
          const SnackBar(content: Text('Account atleta collegato.')),
        );
        context.pop(true);

      case AppFailure(:final message):
        _showMessage(message);
    }
  }

  Future<void> _pickAthleteAccount(List<MemberSummary> members) async {
    final selected = await _showMemberPicker(
      title: 'Seleziona account atleta',
      members: members,
      selectedUserId: _selectedAthleteUserId,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedAthleteUserId = selected.userId;
    });
  }

  Future<void> _pickAthleteProfile(List<AthleteSummary> athletes) async {
    final selected = await _showAthletePicker(
      title: 'Seleziona scheda atleta',
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
                          hintText: 'Nome o email...',
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
                    athlete.userId ?? '',
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
                                    subtitle: Text(_athleteLabel(athlete)),
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

  MemberSummary? _selectedAccountFrom(List<MemberSummary> members) {
    for (final member in members) {
      if (member.userId == _selectedAthleteUserId) {
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
    final accountState = athlete.userId?.trim().isNotEmpty == true
        ? 'account collegato'
        : 'senza account';

    if (teamName == null || teamName.trim().isEmpty) {
      return accountState;
    }

    return '$teamName · $accountState';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collega account atleta')),
      body: FutureBuilder<AppResult<_LinkAthleteAccountData>>(
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
              final athleteAccounts = data.members
                  .where(
                    (member) =>
                        member.hasUserAccount &&
                        !member.isAthleteProfileOnly &&
                        member.role == ClubRole.athlete,
                  )
                  .toList(growable: false);

              final selectedAccount = _selectedAccountFrom(athleteAccounts);
              final selectedAthlete = _selectedAthleteFrom(data.athletes);

              return SafeArea(
                minimum: const EdgeInsets.all(24),
                child: ListView(
                  children: [
                    Text(
                      'Collega account a scheda atleta',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cerca un account atleta e collegalo alla relativa scheda anagrafica.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF52616B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SelectorField(
                      label: 'Account atleta',
                      value: selectedAccount == null
                          ? 'Seleziona account atleta'
                          : selectedAccount.fullName,
                      icon: Icons.person_outline,
                      enabled: !_isLoading,
                      onTap: () => _pickAthleteAccount(athleteAccounts),
                    ),
                    const SizedBox(height: 16),
                    _SelectorField(
                      label: 'Scheda atleta',
                      value: selectedAthlete == null
                          ? 'Seleziona scheda atleta'
                          : '${selectedAthlete.fullName} · ${_athleteLabel(selectedAthlete)}',
                      icon: Icons.directions_run_outlined,
                      enabled: !_isLoading,
                      onTap: () => _pickAthleteProfile(data.athletes),
                    ),
                    const SizedBox(height: 28),
                    AppPrimaryButton(
                      label: 'Collega account',
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

class _LinkAthleteAccountData {
  const _LinkAthleteAccountData({
    required this.members,
    required this.athletes,
  });

  final List<MemberSummary> members;
  final List<AthleteSummary> athletes;
}
