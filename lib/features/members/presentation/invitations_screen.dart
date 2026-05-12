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

  String? _activeClubId;

  @override
  void initState() {
    super.initState();
    _future = _loadInvitations();
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

  Future<void> _copyToken(InvitationSummary invitation) async {
    await Clipboard.setData(ClipboardData(text: invitation.token));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Codice invito copiato.')));
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
                      'Invita allenatori, dirigenti, genitori o atleti tramite email e codice invito.',
                  actionLabel: 'Crea invito',
                  onActionPressed: _goToCreateInvitation,
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
                    final invitation = data[index];

                    return _InvitationCard(
                      invitation: invitation,
                      onCopyToken: () => _copyToken(invitation),
                      onRevoke: invitation.canBeRevoked
                          ? () => _revokeInvitation(invitation)
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

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.onCopyToken,
    required this.onRevoke,
  });

  final InvitationSummary invitation;
  final VoidCallback onCopyToken;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

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
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Codice invito',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            SelectableText(
              invitation.token,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCopyToken,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copia codice'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onRevoke,
                    icon: const Icon(Icons.block_outlined),
                    label: const Text('Revoca'),
                  ),
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
}
