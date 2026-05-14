# ClubManager Sport — Fase 38: Gestione completa squadre

## Obiettivo

Permettere di aprire, consultare, modificare e archiviare una squadra.

## Problema risolto

Prima, cliccando su una squadra compariva solo un messaggio provvisorio. Ora ogni squadra ha una schermata dettaglio e flussi di modifica/archiviazione.

## Funzioni implementate

- Dettaglio squadra.
- Modifica dati squadra.
- Archiviazione squadra.
- Squadre archiviate escluse dalle liste operative.
- Azioni rapide verso atleti, eventi e inviti.
- Route dedicate:
  - `/teams/:teamId`
  - `/teams/:teamId/edit`

## File creati

```text
lib/features/teams/domain/team_detail.dart
lib/features/teams/domain/update_team_request.dart
lib/features/teams/presentation/team_detail_screen.dart
lib/features/teams/presentation/edit_team_screen.dart
supabase/migrations/20260511001600_team_management_hardening.sql
docs/phase-38-team-management.md
File modificati
lib/features/teams/data/team_repository.dart
lib/features/teams/presentation/teams_screen.dart
lib/app/app_router.dart
Archiviazione

La squadra viene tolta dalle liste operative usando:

deleted_at
archived_at
archived_by
archive_reason

Lo storico resta conservato.

Da completare in fasi successive
assegnazione atleti alla squadra;
assegnazione allenatori/staff;
permessi granulari per coach/staff;
audit log su modifica e archiviazione;
dashboard squadra.
Criteri di completamento
supabase db push passa
dart format lib test passa
flutter analyze passa
flutter test passa
cliccando su una squadra si apre il dettaglio
owner/admin/team_manager possono modificare
owner/admin/team_manager possono archiviare
squadra archiviata sparisce dalla lista squadre
Git pulito dopo commit