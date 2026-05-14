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
Campi principali
user_id
push_enabled
event_notifications_enabled
communication_notifications_enabled
document_notifications_enabled
fee_notifications_enabled
created_at
updated_at
Sicurezza

RLS attiva su notification_preferences.

Ogni utente autenticato può:

leggere solo le proprie preferenze;
creare solo le proprie preferenze;
aggiornare solo le proprie preferenze.
Comportamento token push

Quando push_enabled = false:

i token dell’utente vengono segnati come is_active = false.

Quando push_enabled = true:

l’app registra/aggiorna il token FCM corrente;
il token viene segnato come is_active = true.
Test manuale
Effettuare login.
Aprire Profilo utente.
Premere Impostazioni notifiche.
Disattivare Notifiche push.
Verificare in Supabase notification_preferences.push_enabled = false.
Verificare in Supabase push_tokens.is_active = false.
Riattivare Notifiche push.
Verificare push_enabled = true.
Verificare push_tokens.is_active = true.
Attivare/disattivare le categorie.
Verificare salvataggio in Supabase.
Criteri di completamento

La fase è completata quando:

supabase db push passa;
dart format lib test passa;
flutter analyze passa;
flutter test passa;
la schermata impostazioni si apre;
le preferenze vengono caricate;
le preferenze vengono salvate;
i token push vengono disattivati/riattivati;
il commit della fase è stato creato.