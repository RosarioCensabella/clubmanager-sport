import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/create_document_request.dart';
import '../domain/document_summary.dart';
import '../domain/picked_document_file.dart';

class DocumentRepository {
  DocumentRepository();

  static const String bucketId = 'club-documents';

  SupabaseClient get _client => SupabaseService.client;

  String? currentUserId() {
    if (!SupabaseService.isConfigured) {
      return null;
    }

    return _client.auth.currentUser?.id;
  }

  Future<AppResult<List<DocumentSummary>>> fetchDocumentsForClub({
    required String clubId,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (clubId.isEmpty) {
      return const AppFailure(
        'Nessun club attivo selezionato.',
        code: 'active_club_missing',
      );
    }

    try {
      final data = await _client
          .from('documents')
          .select(
            'id, club_id, team_id, athlete_profile_id, title, description, category, scope, status, storage_bucket, file_path, file_name, mime_type, size_bytes, expires_at, created_at',
          )
          .eq('club_id', clubId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(data);

      final teamNames = await _fetchTeamNames(rows);
      final athleteNames = await _fetchAthleteNames(rows);

      final documents = rows
          .map((row) {
            final teamId = row['team_id']?.toString();
            final athleteId = row['athlete_profile_id']?.toString();

            return DocumentSummary.fromMap(
              row,
              teamName: teamId == null ? null : teamNames[teamId],
              athleteName: athleteId == null ? null : athleteNames[athleteId],
            );
          })
          .toList(growable: false);

      return AppSuccess(documents);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare i documenti.',
        code: 'documents_load_error',
      );
    }
  }

  Future<AppResult<String>> uploadAndCreateDocument({
    required PickedDocumentFile file,
    required CreateDocumentRequest requestWithoutFilePath,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    final user = _client.auth.currentUser;

    if (user == null) {
      return const AppFailure(
        'Devi effettuare l’accesso per caricare documenti.',
        code: 'not_authenticated',
      );
    }

    try {
      final storagePath = _buildStoragePath(
        clubId: requestWithoutFilePath.clubId,
        fileName: file.name,
      );

      await _client.storage
          .from(bucketId)
          .uploadBinary(
            storagePath,
            file.bytes,
            fileOptions: FileOptions(contentType: file.mimeType, upsert: false),
          );

      final request = CreateDocumentRequest(
        clubId: requestWithoutFilePath.clubId,
        teamId: requestWithoutFilePath.teamId,
        athleteProfileId: requestWithoutFilePath.athleteProfileId,
        title: requestWithoutFilePath.title,
        description: requestWithoutFilePath.description,
        category: requestWithoutFilePath.category,
        scope: requestWithoutFilePath.scope,
        fileName: file.name,
        filePath: storagePath,
        storageBucket: bucketId,
        mimeType: file.mimeType,
        sizeBytes: file.sizeBytes,
        expiresAt: requestWithoutFilePath.expiresAt,
        uploadedBy: user.id,
      );

      final data = await _client
          .from('documents')
          .insert(request.toInsertMap())
          .select('id')
          .single();

      final documentId = (data['id'] ?? '').toString();

      if (documentId.isEmpty) {
        return const AppFailure(
          'Documento caricato, ma identificativo non ricevuto.',
          code: 'document_created_without_id',
        );
      }

      return AppSuccess(documentId);
    } on StorageException catch (error) {
      return AppFailure(error.message, code: error.statusCode);
    } on PostgrestException catch (error) {
      return AppFailure(error.message, code: error.code);
    } catch (_) {
      return const AppFailure(
        'Impossibile caricare il documento.',
        code: 'document_upload_error',
      );
    }
  }

  Future<AppResult<String>> createSignedUrl({
    required DocumentSummary document,
  }) async {
    if (!SupabaseService.isConfigured) {
      return const AppFailure(
        'Supabase non è configurato.',
        code: 'supabase_not_configured',
      );
    }

    if (document.filePath.isEmpty) {
      return const AppFailure(
        'Percorso file non valido.',
        code: 'invalid_file_path',
      );
    }

    try {
      final url = await _client.storage
          .from(document.storageBucket)
          .createSignedUrl(document.filePath, 60 * 10);

      return AppSuccess(url);
    } on StorageException catch (error) {
      return AppFailure(error.message, code: error.statusCode);
    } catch (_) {
      return const AppFailure(
        'Impossibile aprire il documento.',
        code: 'document_open_error',
      );
    }
  }

  Future<Map<String, String>> _fetchTeamNames(
    List<Map<String, dynamic>> rows,
  ) async {
    final ids = rows
        .map((row) => row['team_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (ids.isEmpty) {
      return {};
    }

    final data = await _client
        .from('teams')
        .select('id, name')
        .inFilter('id', ids);

    final teamRows = List<Map<String, dynamic>>.from(data);

    return {
      for (final row in teamRows)
        (row['id'] ?? '').toString(): (row['name'] ?? '').toString(),
    };
  }

  Future<Map<String, String>> _fetchAthleteNames(
    List<Map<String, dynamic>> rows,
  ) async {
    final ids = rows
        .map((row) => row['athlete_profile_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (ids.isEmpty) {
      return {};
    }

    final data = await _client
        .from('athlete_profiles')
        .select('id, first_name, last_name')
        .inFilter('id', ids);

    final athleteRows = List<Map<String, dynamic>>.from(data);

    return {
      for (final row in athleteRows)
        (row['id'] ?? '').toString():
            '${row['first_name'] ?? ''} ${row['last_name'] ?? ''}'.trim(),
    };
  }

  String _buildStoragePath({required String clubId, required String fileName}) {
    final safeName = fileName
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll('__', '_');

    final timestamp = DateTime.now().microsecondsSinceEpoch;

    return '$clubId/$timestamp-$safeName';
  }
}
