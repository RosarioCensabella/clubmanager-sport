# ClubManager Sport — Fase 22: Profilo utente

## Obiettivo

Implementare una schermata profilo reale per l’utente autenticato.

## Funzioni implementate

- Lettura profilo da Supabase
- Creazione automatica profilo se mancante
- Visualizzazione email
- Visualizzazione ID utente
- Modifica nome e cognome
- Modifica telefono
- Consenso marketing separato dalle comunicazioni operative
- Salvataggio profilo
- Refresh registrazione token push dopo aggiornamento profilo
- Logout
- Collegamento dalla schermata Club e permessi

## File creati

- lib/features/profile/domain/user_profile.dart
- lib/features/profile/data/profile_repository.dart
- lib/features/profile/presentation/profile_providers.dart
- lib/features/profile/presentation/profile_screen.dart
- docs/phase-22-user-profile.md
- supabase/migrations/20260511001100_profile_hardening.sql

## File modificati

- lib/app/app_router.dart
- lib/features/clubs/presentation/club_context_screen.dart

## Tabella Supabase

```text
public.profiles
Campi principali
id
email
full_name
phone_number
avatar_url
preferred_language
marketing_consent
onboarding_completed
created_at
updated_at
Sicurezza

RLS attiva su profiles.

Ogni utente autenticato può:

leggere solo il proprio profilo;
creare solo il proprio profilo;
aggiornare solo il proprio profilo.
Note privacy

Il consenso marketing è separato dalle comunicazioni operative del club.

Le comunicazioni operative, come convocazioni, scadenze, quote e messaggi importanti, non dipendono dal consenso marketing.

Test manuale
Effettuare login.
Aprire Club e permessi.
Premere Profilo utente.
Verificare email e ID utente.
Inserire nome e cognome.
Inserire telefono.
Attivare/disattivare consenso marketing.
Premere Salva profilo.
Verificare aggiornamento in Supabase profiles.
Premere Esci.
Verificare ritorno a Welcome/Login.
Criteri di completamento

La fase è completata quando:

supabase db push passa;
dart format lib test passa;
flutter analyze passa;
flutter test passa;
la schermata profilo si apre;
il profilo viene caricato;
il profilo viene salvato;
il logout funziona;
il commit della fase è stato creato.