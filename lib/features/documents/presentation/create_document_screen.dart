import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../athletes/domain/athlete_summary.dart';
import '../../athletes/presentation/athlete_providers.dart';
import '../../clubs/presentation/club_context_providers.dart';
import '../../teams/domain/team_summary.dart';
import '../../teams/presentation/team_providers.dart';
import '../data/document_repository.dart';
import '../domain/create_document_request.dart';
import '../domain/picked_document_file.dart';
import 'document_providers.dart';

class CreateDocumentScreen extends ConsumerStatefulWidget {
  const CreateDocumentScreen({super.key});

  @override
  ConsumerState<CreateDocumentScreen> createState() =>
      _CreateDocumentScreenState();
}

class _CreateDocumentScreenState extends ConsumerState<CreateDocumentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _expiresAtController = TextEditingController();

  String _category = 'other';
  String _scope = 'club';
  String? _selectedTeamId;
  String? _selectedAthleteId;

  bool _isLoading = false;
  PickedDocumentFile? _pickedFile;

  Future<_TargetsData>? _targetsFuture;
  String? _activeClubId;

  @override
  void initState() {
    super.initState();
    _targetsFuture = _loadTargets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _expiresAtController.dispose();
    super.dispose();
  }

  Future<_TargetsData> _loadTargets() async {
    final clubRepository = ref.read(clubContextRepositoryProvider);
    final teamRepository = ref.read(teamRepositoryProvider);
    final athleteRepository = ref.read(athleteRepositoryProvider);

    _activeClubId = await clubRepository.getActiveClubId();

    if (_activeClubId == null || _activeClubId!.isEmpty) {
      return const _TargetsData(teams: [], athletes: []);
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

    return _TargetsData(teams: teams, athletes: athletes);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    var bytes = file.bytes;

    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }

    if (bytes == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile leggere il file selezionato.'),
        ),
      );
      return;
    }

    final selectedBytes = bytes;

    setState(() {
      _pickedFile = PickedDocumentFile(
        name: file.name,
        bytes: selectedBytes,
        sizeBytes: file.size,
        extension: file.extension,
      );

      if (_titleController.text.trim().isEmpty) {
        _titleController.text = file.name;
      }
    });
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    final file = _pickedFile;

    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona un file da caricare.')),
      );
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
          content: Text(
            'Seleziona o crea un club prima di caricare documenti.',
          ),
        ),
      );
      return;
    }

    final userId = ref.read(documentRepositoryProvider).currentUserId();

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devi effettuare l’accesso.')),
      );
      return;
    }

    if (_scope == 'team' &&
        (_selectedTeamId == null || _selectedTeamId!.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleziona una squadra.')));
      return;
    }

    if (_scope == 'athlete' &&
        (_selectedAthleteId == null || _selectedAthleteId!.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleziona un atleta.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final request = CreateDocumentRequest(
      clubId: clubId,
      teamId: _scope == 'team' ? _selectedTeamId : null,
      athleteProfileId: _scope == 'athlete' ? _selectedAthleteId : null,
      title: _titleController.text,
      description: _descriptionController.text,
      category: _category,
      scope: _scope,
      fileName: file.name,
      filePath: '',
      storageBucket: DocumentRepository.bucketId,
      mimeType: file.mimeType,
      sizeBytes: file.sizeBytes,
      expiresAt: _parseDate(_expiresAtController.text),
      uploadedBy: userId,
    );

    final result = await ref
        .read(documentRepositoryProvider)
        .uploadAndCreateDocument(file: file, requestWithoutFilePath: request);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento caricato correttamente.')),
        );
        context.pop();

      case AppFailure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return DateTime.tryParse(trimmed);
  }

  String? _validateOptionalDate(String? value) {
    final text = value ?? '';

    if (text.isBlank) {
      return null;
    }

    if (DateTime.tryParse(text.trim()) == null) {
      return 'Usa il formato AAAA-MM-GG.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo documento')),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: FutureBuilder<_TargetsData>(
            future: _targetsFuture,
            builder: (context, snapshot) {
              final targets =
                  snapshot.data ?? const _TargetsData(teams: [], athletes: []);

              return ListView(
                children: [
                  Text(
                    'Carica documento',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Carica PDF o immagini e imposta eventuali scadenze.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF52616B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      _pickedFile == null
                          ? 'Seleziona file'
                          : _pickedFile!.name,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Titolo',
                      prefixIcon: Icon(Icons.title_outlined),
                    ),
                    validator: (value) {
                      final title = value ?? '';

                      if (title.isBlank) {
                        return 'Inserisci il titolo.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !_isLoading,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Descrizione',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'medical_certificate',
                        child: Text('Certificato medico'),
                      ),
                      DropdownMenuItem(
                        value: 'identity_document',
                        child: Text('Documento identità'),
                      ),
                      DropdownMenuItem(
                        value: 'membership',
                        child: Text('Tesseramento'),
                      ),
                      DropdownMenuItem(
                        value: 'privacy',
                        child: Text('Privacy'),
                      ),
                      DropdownMenuItem(
                        value: 'payment',
                        child: Text('Pagamento'),
                      ),
                      DropdownMenuItem(value: 'other', child: Text('Altro')),
                    ],
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _category = value;
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _scope,
                    decoration: const InputDecoration(
                      labelText: 'Visibilità',
                      prefixIcon: Icon(Icons.visibility_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'club',
                        child: Text('Tutto il club'),
                      ),
                      DropdownMenuItem(value: 'team', child: Text('Squadra')),
                      DropdownMenuItem(value: 'athlete', child: Text('Atleta')),
                    ],
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _scope = value;
                              _selectedTeamId = null;
                              _selectedAthleteId = null;
                            });
                          },
                  ),
                  if (_scope == 'team') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTeamId,
                      decoration: const InputDecoration(
                        labelText: 'Squadra',
                        prefixIcon: Icon(Icons.groups_2_outlined),
                      ),
                      items: [
                        for (final team in targets.teams)
                          DropdownMenuItem(
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
                    ),
                  ],
                  if (_scope == 'athlete') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAthleteId,
                      decoration: const InputDecoration(
                        labelText: 'Atleta',
                        prefixIcon: Icon(Icons.directions_run_outlined),
                      ),
                      items: [
                        for (final athlete in targets.athletes)
                          DropdownMenuItem(
                            value: athlete.id,
                            child: Text(athlete.fullName),
                          ),
                      ],
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _selectedAthleteId = value;
                              });
                            },
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _expiresAtController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Scadenza',
                      hintText: 'AAAA-MM-GG',
                      prefixIcon: Icon(Icons.event_available_outlined),
                    ),
                    validator: _validateOptionalDate,
                  ),
                  const SizedBox(height: 28),
                  AppPrimaryButton(
                    label: 'Carica documento',
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

class _TargetsData {
  const _TargetsData({required this.teams, required this.athletes});

  final List<TeamSummary> teams;
  final List<AthleteSummary> athletes;
}
