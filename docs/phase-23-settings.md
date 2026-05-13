# ClubManager Sport — Fase 23: Impostazioni

## Obiettivo

Implementare una schermata impostazioni reale per la gestione delle preferenze notifiche.

## Funzioni implementate

- Lettura preferenze notifiche da Supabase
- Creazione preferenze default se mancanti
- Abilitazione/disabilitazione notifiche push
- Preferenze notifiche eventi
- Preferenze notifiche comunicazioni
- Preferenze notifiche documenti e scadenze
- Preferenze notifiche quote associative
- Disattivazione token push quando le notifiche push vengono disabilitate
- Riattivazione/registrazione token push quando le notifiche push vengono abilitate
- Collegamento dalla schermata Profilo utente
- Route `/settings`

## File creati

- lib/features/settings/domain/notification_preferences.dart
- lib/features/settings/data/settings_repository.dart
- lib/features/settings/presentation/settings_providers.dart
- lib/features/settings/presentation/settings_screen.dart
- docs/phase-23-settings.md
- supabase/migrations/20260511001200_settings_preferences_hardening.sql

## File modificati

- lib/app/app_router.dart
- lib/features/profile/presentation/profile_screen.dart

## Tabella Supabase

```text
public.notification_preferences