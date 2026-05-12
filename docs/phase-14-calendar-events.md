# ClubManager Sport — Fase 14: Calendario eventi

## Obiettivo

Implementare la gestione base degli eventi del club.

## Funzioni implementate

- Lista eventi del club attivo
- Stato vuoto calendario
- Creazione evento
- Tipo evento
- Squadra opzionale
- Data e ora inizio
- Data e ora fine opzionale
- Luogo
- Indirizzo
- Descrizione
- Richiesta RSVP
- Visibilità automatica club/squadra

## File creati

- lib/features/events/domain/event_summary.dart
- lib/features/events/domain/create_event_request.dart
- lib/features/events/data/event_repository.dart
- lib/features/events/presentation/event_providers.dart
- lib/features/events/presentation/events_screen.dart
- lib/features/events/presentation/create_event_screen.dart

## File modificati

- lib/app/app_router.dart
- lib/features/clubs/presentation/club_context_screen.dart

## Tabella usata

```text
public.events