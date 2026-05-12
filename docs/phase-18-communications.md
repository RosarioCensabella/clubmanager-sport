# ClubManager Sport — Fase 18: Comunicazioni

## Obiettivo

Implementare le comunicazioni ufficiali del club.

## Funzioni implementate

- Lista comunicazioni
- Dettaglio comunicazione
- Creazione comunicazione
- Comunicazione per tutto il club
- Comunicazione per squadra
- Priorità normale/importante/urgente
- Stato lettura utente
- Predisposizione notifiche push

## File creati

- lib/features/communications/domain/communication_summary.dart
- lib/features/communications/domain/create_communication_request.dart
- lib/features/communications/data/communication_repository.dart
- lib/features/communications/presentation/communication_providers.dart
- lib/features/communications/presentation/communications_screen.dart
- lib/features/communications/presentation/create_communication_screen.dart
- lib/features/communications/presentation/communication_detail_screen.dart
- docs/phase-18-communications.md
- supabase/migrations/20260511000700_communications_hardening.sql

## File modificati

- lib/app/app_router.dart

## Tabelle usate

```text
public.announcements
public.announcement_reads