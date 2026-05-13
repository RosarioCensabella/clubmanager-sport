# ClubManager Sport — Fase 31: Pubblicazione pagine legali e aggiornamento URL app

## Obiettivo

Pubblicare online le pagine legali pubbliche e configurare l’app con gli URL reali.

## Repository pubblico separato

Le pagine legali sono state pubblicate in un repository separato dal codice sorgente principale dell’app.

Repository:

```text
clubmanager-sport-legal-pages

Motivo:

evitare di rendere pubblico il repository principale dell’app;
pubblicare solo le pagine richieste per store e compliance;
mantenere separato il codice applicativo dalle pagine pubbliche.
URL pubblici configurati

Privacy Policy:

https://RosarioCensabella.github.io/clubmanager-sport-legal-pages/privacy-policy.html

Termini d’uso:

https://RosarioCensabella.github.io/clubmanager-sport-legal-pages/terms-of-service.html

Richiesta eliminazione account:

https://RosarioCensabella.github.io/clubmanager-sport-legal-pages/account-deletion.html
File aggiornato
lib/core/config/app_store_config.dart

Campi aggiornati:

privacyPolicyUrl
termsOfServiceUrl
accountDeletionRequestUrl
Effetto nell’app

La checklist store interna ora può rilevare che sono configurati:

Privacy policy pubblica;
Termini d’uso pubblici;
Link web pubblico eliminazione account.
Note store

Il link pubblico per eliminazione account sarà utile per Google Play Console nella sezione relativa alla gestione dati/account.

Il percorso in-app resta disponibile da:

Profilo utente → Impostazioni notifiche → Privacy e account
Criteri di completamento

La fase è completata quando:

le pagine pubbliche sono online;
gli URL si aprono da browser;
app_store_config.dart contiene gli URL reali;
flutter analyze passa;
flutter test passa;
flutter build appbundle --release passa;
Git è pulito dopo il commit.