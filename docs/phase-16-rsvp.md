# ClubManager Sport — Fase 16: RSVP / conferme presenza

## Obiettivo

Implementare la gestione iniziale delle conferme presenza per gli atleti convocati.

## Funzioni implementate

- Riepilogo RSVP per evento
- Stato in attesa
- Conferma presenza
- Segna non disponibile
- Ripristina in attesa
- Nota risposta opzionale
- Salvataggio utente che aggiorna la risposta
- Salvataggio data/ora risposta

## File modificati

- lib/features/callups/domain/callup_summary.dart
- lib/features/callups/data/callup_repository.dart
- lib/features/events/presentation/event_detail_screen.dart

## File creati

- docs/phase-16-rsvp.md
- supabase/migrations/20260511000500_event_callups_rsvp_fields.sql

## Tabella usata

```text
public.event_callups