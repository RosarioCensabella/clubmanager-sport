# ClubManager Sport — Fase 9: Ruoli e permessi

## Obiettivo

Implementare lo strato applicativo per ruoli, permessi e club attivo.

## Principio fondamentale

La UI Flutter può mostrare o nascondere funzioni, ma la sicurezza reale deve restare nel backend.

I permessi definitivi sono verificati con:

- Supabase Row Level Security;
- policy SQL;
- helper functions;
- relazioni club/squadra/atleta/genitore.

## Ruoli supportati

- owner
- admin
- team_manager
- coach
- athlete
- parent
- staff

## File creati

- lib/core/permissions/club_role.dart
- lib/core/permissions/app_permission.dart
- lib/core/permissions/permission_policy.dart
- lib/features/clubs/domain/club_summary.dart
- lib/features/clubs/domain/club_membership_summary.dart
- lib/features/clubs/data/club_context_repository.dart
- lib/features/clubs/presentation/club_context_providers.dart
- lib/features/clubs/presentation/club_context_screen.dart

## File modificati

- lib/app/app_router.dart
- lib/features/auth/presentation/login_screen.dart

## Club attivo

Il club attivo viene salvato localmente con SharedPreferences.

Chiave usata:

```text
active_club_id