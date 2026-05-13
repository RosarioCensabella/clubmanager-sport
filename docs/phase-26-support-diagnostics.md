# ClubManager Sport — Fase 26: Supporto e diagnostica

## Obiettivo

Aggiungere una schermata di supporto e diagnostica utile per assistenza utenti, debug e preparazione alla pubblicazione.

## Funzioni implementate

- Schermata Supporto e diagnostica
- Email supporto
- Apertura client email con testo precompilato
- Informazioni app
- Package name
- Versione e build number
- Piattaforma
- Stato configurazione Supabase
- User ID autenticato
- Email utente autenticato
- Suggerimenti base di troubleshooting
- Route `/support`
- Collegamento da Impostazioni

## File creati

- lib/features/support/presentation/support_screen.dart
- docs/phase-26-support-diagnostics.md

## File modificati

- lib/app/app_router.dart
- lib/features/settings/presentation/settings_screen.dart

## Configurazione

L’email supporto si trova in:

```text
lib/core/config/app_store_config.dart

Campo:

supportEmail
Test manuale
Effettuare login.
Aprire Profilo utente.
Aprire Impostazioni notifiche.
Aprire Supporto e diagnostica.
Verificare:
app name;
package name;
versione;
piattaforma;
Supabase configurato;
user ID;
email utente.
Premere Contatta supporto.
Verificare apertura app email o messaggio fallback.
Criteri di completamento

La fase è completata quando:

dart format lib test passa;
flutter analyze passa;
flutter test passa;
la schermata supporto si apre;
le informazioni diagnostiche sono visibili;
il collegamento email supporto funziona o mostra fallback;
il commit della fase è stato creato.