# ClubManager Sport — Fase 17: Presenze

## Obiettivo

Implementare il registro presenze per gli eventi.

## Funzioni implementate

- Registro presenze da evento
- Elenco convocati
- Segna presente
- Segna assente
- Segna in ritardo
- Segna giustificato
- Ripristina da registrare
- Riepilogo presenze
- Salvataggio utente registratore
- Salvataggio data/ora registrazione

## File creati

- lib/features/attendance/domain/attendance_summary.dart
- lib/features/attendance/data/attendance_repository.dart
- lib/features/attendance/presentation/attendance_providers.dart
- lib/features/attendance/presentation/attendance_screen.dart
- docs/phase-17-attendance.md
- supabase/migrations/20260511000600_attendance_hardening.sql

## File modificati

- lib/features/events/presentation/events_screen.dart
- lib/app/app_router.dart

## Tabelle usate

```text
public.attendance
public.event_callups