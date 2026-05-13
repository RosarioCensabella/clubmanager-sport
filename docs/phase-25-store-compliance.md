# ClubManager Sport — Fase 25: Preparazione store e compliance base

## Obiettivo

Preparare la base in-app per la pubblicazione su App Store e Google Play.

## Funzioni implementate

- Centro documenti legali
- Informativa privacy in-app
- Termini d’uso in-app
- Informazioni eliminazione account
- Informazioni app e versione
- Checklist store interna
- Route `/legal`
- Route `/legal/:documentId`
- Collegamento da Impostazioni

## File creati

- lib/core/config/app_store_config.dart
- lib/features/legal/domain/legal_document.dart
- lib/features/legal/presentation/legal_center_screen.dart
- lib/features/legal/presentation/legal_document_screen.dart
- docs/phase-25-store-compliance.md

## File modificati

- lib/app/app_router.dart
- lib/features/settings/presentation/settings_screen.dart

## Requisiti store coperti

- percorso in-app per eliminazione account;
- informativa privacy accessibile dentro l’app;
- termini d’uso accessibili dentro l’app;
- informazioni app/versione visibili;
- base per privacy policy pubblica;
- base per link web pubblico eliminazione account.

## Cose ancora da completare prima della pubblicazione

- Privacy policy pubblica ospitata online
- Termini d’uso pubblici ospitati online
- Link web pubblico per richiesta eliminazione account
- Icone definitive
- Splash screen definitivo
- Screenshot store
- Descrizione breve e completa store
- Classificazione contenuti
- Data Safety Google Play
- App Privacy Apple
- Configurazione firma Android release
- Configurazione Apple Developer e APNs iOS
- Test release build
- Test su dispositivo fisico Android
- Test su dispositivo fisico iPhone

## Configurazione URL pubblici

I placeholder sono in:

```text
lib/core/config/app_store_config.dart

Campi da valorizzare prima della pubblicazione:

privacyPolicyUrl
termsOfServiceUrl
accountDeletionRequestUrl
Nota legale

I testi privacy e termini d’uso inseriti nell’app sono una base tecnica. Prima della pubblicazione devono essere verificati e completati dal punto di vista legale.

Test manuale
Effettuare login.
Aprire Profilo utente.
Aprire Impostazioni notifiche.
Aprire Documenti legali e informazioni app.
Aprire Informativa privacy.
Aprire Termini d’uso.
Aprire Eliminazione account.
Verificare informazioni app/versione.
Verificare checklist store.
Aprire Privacy e account dal centro legale.
Criteri di completamento

La fase è completata quando:

dart format lib test passa;
flutter analyze passa;
flutter test passa;
il centro legale si apre;
i documenti legali si aprono;
le informazioni app sono visibili;
il commit della fase è stato creato.