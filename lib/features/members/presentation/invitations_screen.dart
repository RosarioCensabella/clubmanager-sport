import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../domain/invitation_summary.dart';
import 'invitation_providers.dart';

class InvitationsScreen extends ConsumerStatefulWidget {
  const InvitationsScreen({super.key});

  @override
  ConsumerState<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends ConsumerState<InvitationsScreen> {
  late Future<AppResult<List<InvitationSummary>>> _future;

  final _searchController = TextEditingController();
  final Set<String> _sendingInvitationIds = {};

  _InvitationFilter _filter = _InvitationFilter.all;
  String? _activeClubId;

  @override
  void initState() {
    super.initState();
    _future = _loadInvitations();

    _searchController.addListener(() {
      if (!mounted) {
        return;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<AppResult<List<InvitationSummary>>> _loadInvitations() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final invitationRepository = ref.read(invitationRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return const AppFailure(
        'Seleziona o crea un club prima di gestire gli inviti.',
        code: 'active_club_missing',
      );
    }

    return invitationRepository.fetchInvitationsForClub(clubId: _activeClubId!);
  }

  void _reload() {
    setState(() {
      _future = _loadInvitations();
    });
  }

  void _goToCreateInvitation() {
    context.push('/invitations/create').then((_) => _reload());
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _filter = _InvitationFilter.all;
    });
  }

  List<InvitationSummary> _filteredInvitations(
    List<InvitationSummary> invitations,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    return invitations
        .where((invitation) {
          final matchesFilter = switch (_filter) {
            _InvitationFilter.all => true,
            _InvitationFilter.active =>
              invitation.status == 'sent' && !invitation.isExpired,
            _InvitationFilter.emailSent => invitation.emailSentAt != null,
            _InvitationFilter.emailPending =>
              invitation.emailSentAt == null &&
                  (invitation.emailLastError == null ||
                      invitation.emailLastError!.trim().isEmpty),
            _InvitationFilter.emailFailed =>
              invitation.emailLastError != null &&
                  invitation.emailLastError!.trim().isNotEmpty,
            _InvitationFilter.accepted => invitation.status == 'accepted',
            _InvitationFilter.revoked => invitation.status == 'revoked',
            _InvitationFilter.expired =>
              invitation.status == 'expired' || invitation.isExpired,
          };

          if (!matchesFilter) {
            return false;
          }

          if (query.isEmpty) {
            return true;
          }

          final searchable = [
            invitation.email,
            invitation.role.label,
            invitation.statusLabel,
            invitation.emailStatusLabel,
            invitation.teamName ?? '',
            invitation.token,
          ].join(' ').toLowerCase();

          return searchable.contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _copyLink(InvitationSummary invitation) async {
    final link = ref
        .read(invitationRepositoryProvider)
        .buildInvitationLink(invitation.token);

    await Clipboard.setData(ClipboardData(text: link));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link invito copiato.')));
  }

  Future<void> _sendEmail(InvitationSummary invitation) async {
    setState(() {
      _sendingInvitationIds.add(invitation.id);
    });

    final result = await ref
        .read(invitationRepositoryProvider)
        .sendInvitationEmail(invitationId: invitation.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _sendingInvitationIds.remove(invitation.id);
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Email invito inviata.')));
        _reload();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        _reload();
    }
  }

  Future<void> _revokeInvitation(InvitationSummary invitation) async {
    final shouldRevoke = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Revocare invito?'),
          content: Text(
            'L’invito per ${invitation.email} non potrà più essere accettato.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Revoca'),
            ),
          ],
        );
      },
    );

    if (shouldRevoke != true) {
      return;
    }

    final result = await ref
        .read(invitationRepositoryProvider)
        .revokeInvitation(invitationId: invitation.id);

    if (!mounted) {
      return;
    }

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invito revocato.')));
        _reload();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteInvitation(InvitationSummary invitation) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancellare invito?'),
          content: Text(
            'L’invito revocato per ${invitation.email} verrà eliminato definitivamente dalla lista.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cancella'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final result = await ref
        .read(invitationRepositoryProvider)
        .deleteInvitation(invitationId: invitation.id);

    if (!mounted) {
      return;
    }

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invito cancellato.')));
        _reload();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inviti'),
        actions: [
          IconButton(
            tooltip: 'Nuovo invito',
            onPressed: _goToCreateInvitation,
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      body: FutureBuilder<AppResult<List<InvitationSummary>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(message: 'Caricamento inviti...');
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
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'Nessun invito',
                  message:
                      'Invita allenatori, dirigenti, genitori o atleti tramite email e link invito.',
                  actionLabel: 'Crea invito',
                  onActionPressed: _goToCreateInvitation,
                );
              }

              final filteredData = _filteredInvitations(data);

              return RefreshIndicator(
                onRefresh: () async {
                  _reload();
                  await _future;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredData.isEmpty ? 2 : filteredData.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _InvitationFiltersCard(
                        searchController: _searchController,
                        selectedFilter: _filter,
                        totalCount: data.length,
                        filteredCount: filteredData.length,
                        onFilterChanged: (filter) {
                          setState(() {
                            _filter = filter;
                          });
                        },
                        onClearPressed: _clearFilters,
                      );
                    }

                    if (filteredData.isEmpty) {
                      return _FilteredEmptyCard(onClearPressed: _clearFilters);
                    }

                    final invitation = filteredData[index - 1];
                    final isSending = _sendingInvitationIds.contains(
                      invitation.id,
                    );
                    final link = ref
                        .read(invitationRepositoryProvider)
                        .buildInvitationLink(invitation.token);

                    return _InvitationCard(
                      invitation: invitation,
                      invitationLink: link,
                      isSendingEmail: isSending,
                      onCopyLink: () => _copyLink(invitation),
                      onSendEmail: invitation.canSendEmail
                          ? () => _sendEmail(invitation)
                          : null,
                      onRevoke: invitation.canBeRevoked
                          ? () => _revokeInvitation(invitation)
                          : null,
                      onDelete: invitation.canBeDeleted
                          ? () => _deleteInvitation(invitation)
                          : null,
                    );
                  },
                ),
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreateInvitation,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Nuovo invito'),
      ),
    );
  }
}

enum _InvitationFilter {
  all,
  active,
  emailSent,
  emailPending,
  emailFailed,
  accepted,
  revoked,
  expired,
}

extension _InvitationFilterLabel on _InvitationFilter {
  String get label {
    switch (this) {
      case _InvitationFilter.all:
        return 'Tutti';
      case _InvitationFilter.active:
        return 'Attivi';
      case _InvitationFilter.emailSent:
        return 'Email inviata';
      case _InvitationFilter.emailPending:
        return 'Email da inviare';
      case _InvitationFilter.emailFailed:
        return 'Email errore';
      case _InvitationFilter.accepted:
        return 'Accettati';
      case _InvitationFilter.revoked:
        return 'Revocati';
      case _InvitationFilter.expired:
        return 'Scaduti';
    }
  }

  IconData get icon {
    switch (this) {
      case _InvitationFilter.all:
        return Icons.all_inbox_outlined;
      case _InvitationFilter.active:
        return Icons.mark_email_unread_outlined;
      case _InvitationFilter.emailSent:
        return Icons.mark_email_read_outlined;
      case _InvitationFilter.emailPending:
        return Icons.outgoing_mail;
      case _InvitationFilter.emailFailed:
        return Icons.error_outline;
      case _InvitationFilter.accepted:
        return Icons.check_circle_outline;
      case _InvitationFilter.revoked:
        return Icons.block_outlined;
      case _InvitationFilter.expired:
        return Icons.timer_off_outlined;
    }
  }
}

class _InvitationFiltersCard extends StatelessWidget {
  const _InvitationFiltersCard({
    required this.searchController,
    required this.selectedFilter,
    required this.totalCount,
    required this.filteredCount,
    required this.onFilterChanged,
    required this.onClearPressed,
  });

  final TextEditingController searchController;
  final _InvitationFilter selectedFilter;
  final int totalCount;
  final int filteredCount;
  final ValueChanged<_InvitationFilter> onFilterChanged;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters =
        searchController.text.trim().isNotEmpty ||
        selectedFilter != _InvitationFilter.all;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cerca e filtra',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Cerca invito',
                hintText: 'Email, ruolo, squadra, stato o codice',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => searchController.clear(),
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in _InvitationFilter.values)
                  ChoiceChip(
                    selected: selectedFilter == filter,
                    avatar: Icon(filter.icon, size: 18),
                    label: Text(filter.label),
                    onSelected: (_) => onFilterChanged(filter),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$filteredCount di $totalCount inviti mostrati',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF52616B),
                    ),
                  ),
                ),
                if (hasActiveFilters)
                  TextButton.icon(
                    onPressed: onClearPressed,
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Pulisci'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilteredEmptyCard extends StatelessWidget {
  const _FilteredEmptyCard({required this.onClearPressed});

  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Nessun invito trovato',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Modifica ricerca o filtri per vedere altri inviti.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF52616B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onClearPressed,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Pulisci filtri'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.invitationLink,
    required this.isSendingEmail,
    required this.onCopyLink,
    required this.onSendEmail,
    required this.onRevoke,
    required this.onDelete,
  });

  final InvitationSummary invitation;
  final String invitationLink;
  final bool isSendingEmail;
  final VoidCallback onCopyLink;
  final VoidCallback? onSendEmail;
  final VoidCallback? onRevoke;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final emailColor = _emailColor();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.mail_outline),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.email,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invitation.teamName == null
                            ? invitation.role.label
                            : '${invitation.role.label} · ${invitation.teamName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF52616B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(invitation.statusLabel),
                  avatar: Icon(Icons.circle, color: statusColor, size: 14),
                ),
                Chip(
                  label: Text(invitation.isExpired ? 'Scaduto' : 'Valido'),
                  avatar: Icon(
                    invitation.isExpired
                        ? Icons.timer_off_outlined
                        : Icons.timer_outlined,
                    size: 18,
                  ),
                ),
                Chip(
                  label: Text(invitation.emailStatusLabel),
                  avatar: Icon(
                    Icons.email_outlined,
                    color: emailColor,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Link invito',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            SelectableText(
              invitationLink,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (invitation.emailLastError != null &&
                invitation.emailLastError!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Ultimo errore email',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFC62828),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                invitation.emailLastError!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFFC62828)),
              ),
            ],
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: onCopyLink,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copia link'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: isSendingEmail ? null : onSendEmail,
                  icon: const Icon(Icons.email_outlined),
                  label: Text(
                    isSendingEmail ? 'Invio email...' : 'Invia email',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onRevoke,
                  icon: const Icon(Icons.block_outlined),
                  label: const Text('Revoca'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Cancella invito'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor() {
    switch (invitation.status) {
      case 'sent':
        return const Color(0xFF176B87);
      case 'accepted':
        return const Color(0xFF2E7D32);
      case 'expired':
        return const Color(0xFFF9A825);
      case 'revoked':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _emailColor() {
    if (invitation.emailSentAt != null) {
      return const Color(0xFF2E7D32);
    }

    if (invitation.emailLastError != null &&
        invitation.emailLastError!.trim().isNotEmpty) {
      return const Color(0xFFC62828);
    }

    return const Color(0xFF64748B);
  }
}
