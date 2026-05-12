# ClubManager Sport — Fase 11: Gestione squadre

## Obiettivo

Implementare la gestione base delle squadre del club.

## Funzioni implementate

- Lettura club attivo
- Lista squadre del club
- Stato vuoto se non ci sono squadre
- Creazione nuova squadra
- Salvataggio squadra su Supabase
- Ritorno alla lista dopo creazione

## File creati

- lib/features/teams/domain/team_summary.dart
- lib/features/teams/domain/create_team_request.dart
- lib/features/teams/data/team_repository.dart
- lib/features/teams/presentation/team_providers.dart
- lib/features/teams/presentation/teams_screen.dart
- lib/features/teams/presentation/create_team_screen.dart

## File modificati

- lib/features/clubs/presentation/club_context_screen.dart
- lib/app/app_router.dart

## Campi squadra gestiti

Obbligatori:

- nome squadra
- sport
- genere

Opzionali:

- categoria
- stagione
- anno di nascita
- luogo allenamenti
- colore squadra

## Backend

La tabella usata è:

```text
public.teams