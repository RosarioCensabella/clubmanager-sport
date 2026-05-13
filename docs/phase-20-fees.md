# ClubManager Sport — Fase 20: Quote associative

## Obiettivo

Implementare gestione quote associative e pagamenti manuali.

## Funzioni implementate

- Lista quote del club
- Creazione quota
- Quota per tutto il club
- Quota per squadra
- Quota per atleti selezionati
- Assegnazioni quota agli atleti
- Dettaglio quota
- Riepilogo pagamenti
- Cambio stato pagamento manuale
- RLS lato backend

## File creati

- lib/features/fees/domain/fee_summary.dart
- lib/features/fees/domain/fee_assignment_summary.dart
- lib/features/fees/domain/create_fee_request.dart
- lib/features/fees/data/fee_repository.dart
- lib/features/fees/presentation/fee_providers.dart
- lib/features/fees/presentation/fees_screen.dart
- lib/features/fees/presentation/create_fee_screen.dart
- lib/features/fees/presentation/fee_detail_screen.dart
- docs/phase-20-fees.md
- supabase/migrations/20260511000900_fees_preflight.sql
- supabase/migrations/20260511000910_fees_hardening.sql

## File modificati

- lib/app/app_router.dart
- lib/features/clubs/presentation/club_context_screen.dart

## Tabelle usate

```text
public.fees
public.fee_assignments