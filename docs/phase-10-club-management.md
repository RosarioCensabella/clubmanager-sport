# ClubManager Sport — Fase 10: Gestione club

## Obiettivo

Implementare il primo flusso reale di gestione club.

## Funzioni implementate

- Creazione nuovo club dall'app
- Salvataggio club su Supabase
- Creazione automatica membership owner tramite trigger database
- Salvataggio club attivo locale
- Ritorno alla schermata Club e permessi

## File creati

- lib/features/clubs/domain/create_club_request.dart
- lib/features/clubs/presentation/create_club_screen.dart

## File modificati

- lib/features/clubs/data/club_context_repository.dart
- lib/features/clubs/presentation/club_context_screen.dart
- lib/app/app_router.dart

## Campi club gestiti

Obbligatori:

- nome club
- sport principale
- città

Opzionali:

- stagione sportiva
- indirizzo sede
- email ufficiale
- telefono
- sito web
- codice fiscale / partita IVA

## Backend

La tabella usata è:

```text
public.clubs