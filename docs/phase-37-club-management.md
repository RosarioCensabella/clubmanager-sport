# ClubManager Sport — Fase 37: Gestione completa club

## Obiettivo

Permettere di aprire, consultare, modificare e archiviare un club.

## Problema risolto

Prima, cliccando su un club si poteva solo selezionare il contesto o aprire il workspace, ma non era presente una vera gestione dei dati del club.

## Funzioni implementate

- Dettaglio club.
- Modifica dati club.
- Archiviazione club.
- Esclusione dei club archiviati dalla selezione operativa.
- Accesso alla gestione club dal workspace.
- Protezione UI: solo owner/admin possono modificare e archiviare.
- Archiviazione come soft delete, non eliminazione fisica.

## File creati

```text
lib/features/clubs/domain/club_detail.dart
lib/features/clubs/domain/club_management_data.dart
lib/features/clubs/domain/update_club_request.dart
lib/features/clubs/presentation/club_detail_screen.dart
lib/features/clubs/presentation/edit_club_screen.dart
supabase/migrations/20260511001500_club_management_hardening.sql
docs/phase-37-club-management.md
File modificati
lib/features/clubs/domain/club_summary.dart
lib/features/clubs/data/club_context_repository.dart
lib/features/clubs/presentation/club_workspace_screen.dart
lib/app/app_router.dart
Archiviazione

Il club viene tolto dalle liste operative usando:

deleted_at
archived_at
archived_by
archive_reason

Lo storico resta conservato.

Route aggiunte
/clubs/:clubId
/clubs/:clubId/edit
Da completare in fasi successive
gestione membri del club;
revoca accesso;
permessi granulari;
audit log per modifiche e archiviazione;
eventuale ripristino club archiviato da platform admin.
Criteri di completamento
supabase db push passa
dart format lib test passa
flutter analyze passa
flutter test passa
dal workspace si apre gestione club
owner/admin possono modificare
owner/admin possono archiviare
club archiviato sparisce dalla lista club
Git pulito dopo commit