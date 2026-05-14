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
  String _accountQuery = '';
  String _athleteQuery = '';
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

  List<MemberSummary> _athleteAccounts(List<MemberSummary> members) {
    final normalizedQuery = _accountQuery.trim().toLowerCase();

    return members
        .where((member) => member.userId.trim().isNotEmpty)
        .where((member) => member.role == ClubRole.athlete)
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
            athlete.userId ?? '',
          ].join(' ').toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
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

    return '$teamName Â· $accountState';
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
              onRetry: _reload,
            );
          }

          switch (result) {
            case AppFailure(:final message):
              return AppErrorView(message: message, onRetry: _reload);

            case AppSuccess(:final data):
              final visibleAccounts = _athleteAccounts(data.members);
              final visibleAthletes = _filteredAthletes(data.athletes);
              final selectedAccount = _selectedAccountFrom(data.members);
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
                    if (selectedAccount != null)
                      _SelectedValueCard(
                        icon: Icons.person_outline,
                        title: 'Account selezionato',
                        value: selectedAccount.fullName,
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Cerca account atleta',
                        hintText: 'Nome o email...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _accountQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _SectionTitle(title: 'Account atleta disponibili'),
                    const SizedBox(height: 8),
                    if (visibleAccounts.isEmpty)
                      const _EmptyInlineMessage(
                        message:
                            'Nessun account atleta trovato. Invitalo prima come Atleta.',
                      )
                    else
                      for (final account in visibleAccounts) ...[
                        _SelectableAccountTile(
                          member: account,
                          selected: account.userId == _selectedAthleteUserId,
                          enabled: !_isLoading,
                          onTap: () {
                            setState(() {
                              _selectedAthleteUserId = account.userId;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 16),
                    if (selectedAthlete != null)
                      _SelectedValueCard(
                        icon: Icons.directions_run_outlined,
                        title: 'Scheda atleta selezionata',
                        value:
                            '${selectedAthlete.fullName} Â· ${_athleteLabel(selectedAthlete)}',
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Cerca scheda atleta',
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
                    _SectionTitle(title: 'Schede atleta disponibili'),
                    const SizedBox(height: 8),
                    if (visibleAthletes.isEmpty)
                      const _EmptyInlineMessage(
                        message: 'Nessuna scheda atleta trovata.',
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

class _LinkAthleteAccountData {
  const _LinkAthleteAccountData({
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

class _SelectableAccountTile extends StatelessWidget {
  const _SelectableAccountTile({
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
