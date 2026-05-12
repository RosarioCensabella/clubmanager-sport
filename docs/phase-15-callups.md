# ClubManager Sport — Fase 15: Convocazioni

## Obiettivo

Implementare la gestione base delle convocazioni per gli eventi.

## Funzioni implementate

- Dettaglio evento
- Lista convocati evento
- Aggiunta atleti convocati
- Filtro automatico per squadra evento
- Prevenzione duplicati tramite upsert
- Rimozione convocazione
- Stato convocazione base

## File creati

- lib/features/callups/domain/callup_summary.dart
- lib/features/callups/data/callup_repository.dart
- lib/features/callups/presentation/callup_providers.dart
- lib/features/callups/presentation/add_callups_screen.dart
- lib/features/events/presentation/event_detail_screen.dart
- docs/phase-15-callups.md

## File modificati

- lib/features/events/data/event_repository.dart
- lib/features/events/presentation/events_screen.dart
- lib/app/app_router.dart

## Migration

- supabase/migrations/20260511000300_event_callups_hardening.sql

## Tabella usata

```text
public.event_callups