# ClubManager Sport — Fase 19: Documenti e scadenze

## Obiettivo

Implementare gestione documenti e scadenze.

## Funzioni implementate

- Upload file su Supabase Storage
- Salvataggio metadati documento
- Lista documenti
- Lista scadenze
- Documento per club
- Documento per squadra
- Documento per atleta
- Categorie documento
- URL firmato per apertura sicura
- RLS su documenti
- RLS su storage

## File creati

- lib/features/documents/domain/document_summary.dart
- lib/features/documents/domain/create_document_request.dart
- lib/features/documents/domain/picked_document_file.dart
- lib/features/documents/data/document_repository.dart
- lib/features/documents/presentation/document_providers.dart
- lib/features/documents/presentation/documents_screen.dart
- lib/features/documents/presentation/create_document_screen.dart
- docs/phase-19-documents-and-deadlines.md
- supabase/migrations/20260511000800_documents_and_deadlines.sql

## File modificati

- pubspec.yaml
- pubspec.lock
- lib/app/app_router.dart
- lib/features/clubs/presentation/club_context_screen.dart

## Storage bucket

```text
club-documents