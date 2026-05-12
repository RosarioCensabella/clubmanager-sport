import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../domain/document_summary.dart';
import 'document_providers.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  late Future<AppResult<List<DocumentSummary>>> _future;

  String? _activeClubId;

  @override
  void initState() {
    super.initState();
    _future = _loadDocuments();
  }

  Future<AppResult<List<DocumentSummary>>> _loadDocuments() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final documentRepository = ref.read(documentRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return const AppFailure(
        'Seleziona o crea un club prima di gestire i documenti.',
        code: 'active_club_missing',
      );
    }

    return documentRepository.fetchDocumentsForClub(clubId: _activeClubId!);
  }

  void _reload() {
    setState(() {
      _future = _loadDocuments();
    });
  }

  void _goToCreateDocument() {
    context.push('/documents/create').then((_) => _reload());
  }

  Future<void> _openDocument(DocumentSummary document) async {
    final result = await ref
        .read(documentRepositoryProvider)
        .createSignedUrl(document: document);

    if (!mounted) {
      return;
    }

    switch (result) {
      case AppSuccess(:final data):
        final uri = Uri.tryParse(data);

        if (uri == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('URL documento non valido.')),
          );
          return;
        }

        await launchUrl(uri, mode: LaunchMode.externalApplication);

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
        title: const Text('Documenti'),
        actions: [
          IconButton(
            tooltip: 'Nuovo documento',
            onPressed: _goToCreateDocument,
            icon: const Icon(Icons.upload_file_outlined),
          ),
        ],
      ),
      body: FutureBuilder<AppResult<List<DocumentSummary>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(message: 'Caricamento documenti...');
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
                  icon: Icons.folder_copy_outlined,
                  title: 'Nessun documento',
                  message:
                      'Carica certificati, documenti di tesseramento o altri file del club.',
                  actionLabel: 'Carica documento',
                  onActionPressed: _goToCreateDocument,
                );
              }

              final deadlines =
                  data
                      .where((document) => document.hasDeadline)
                      .toList(growable: false)
                    ..sort((a, b) => a.expiresAt!.compareTo(b.expiresAt!));

              return RefreshIndicator(
                onRefresh: () async {
                  _reload();
                  await _future;
                },
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _SectionHeader(
                      title: 'Scadenze',
                      subtitle: deadlines.isEmpty
                          ? 'Nessuna scadenza registrata.'
                          : null,
                    ),
                    if (deadlines.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Text('Nessun documento con scadenza.'),
                        ),
                      )
                    else
                      for (final document in deadlines.take(5)) ...[
                        _DocumentCard(
                          document: document,
                          compact: true,
                          onOpenPressed: () => _openDocument(document),
                        ),
                        const SizedBox(height: 12),
                      ],
                    const SizedBox(height: 12),
                    const _SectionHeader(title: 'Tutti i documenti'),
                    const SizedBox(height: 12),
                    for (final document in data) ...[
                      _DocumentCard(
                        document: document,
                        onOpenPressed: () => _openDocument(document),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreateDocument,
        icon: const Icon(Icons.upload_file_outlined),
        label: const Text('Carica'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF52616B)),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.onOpenPressed,
    this.compact = false,
  });

  final DocumentSummary document;
  final VoidCallback onOpenPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final deadlineColor = document.isExpired
        ? const Color(0xFFC62828)
        : document.isExpiringSoon
        ? const Color(0xFFF9A825)
        : const Color(0xFF2E7D32);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: deadlineColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.description_outlined),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    document.fileName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF52616B),
                    ),
                  ),
                  if (!compact &&
                      document.description != null &&
                      document.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(document.description!),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(document.categoryLabel),
                        avatar: const Icon(Icons.category_outlined, size: 18),
                      ),
                      Chip(
                        label: Text(document.scopeLabel),
                        avatar: const Icon(Icons.visibility_outlined, size: 18),
                      ),
                      if (document.expiresAt != null)
                        Chip(
                          label: Text(_deadlineText()),
                          avatar: const Icon(
                            Icons.event_available_outlined,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: onOpenPressed,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Apri documento'),
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

  String _deadlineText() {
    final expiry = document.expiresAt;

    if (expiry == null) {
      return 'Nessuna scadenza';
    }

    final day = expiry.day.toString().padLeft(2, '0');
    final month = expiry.month.toString().padLeft(2, '0');
    final year = expiry.year.toString().padLeft(4, '0');

    if (document.isExpired) {
      return 'Scaduto $day/$month/$year';
    }

    if (document.isExpiringSoon) {
      return 'In scadenza $day/$month/$year';
    }

    return 'Scade $day/$month/$year';
  }
}
