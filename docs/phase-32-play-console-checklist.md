# ClubManager Sport — Fase 32: Build finale AAB e checklist Play Console

## Obiettivo

Generare l’Android App Bundle finale e preparare la checklist operativa per Google Play Console.

## Build finale

Output atteso:

```text
build/app/outputs/bundle/release/app-release.aab

Versione app:

1.0.0+1
URL pubblici

Privacy Policy:

https://RosarioCensabella.github.io/clubmanager-sport-legal-pages/privacy-policy.html

Termini d’uso:

https://RosarioCensabella.github.io/clubmanager-sport-legal-pages/terms-of-service.html

Eliminazione account:

https://RosarioCensabella.github.io/clubmanager-sport-legal-pages/account-deletion.html
Checklist tecnica pre-upload
git status pulito
dart format lib test passa
flutter analyze passa
flutter test passa
flutter build appbundle --release passa
app-release.aab generato
android/key.properties ignorato da Git
keystore .jks salvato fuori dal repository
URL pubblici legali online
Checklist Play Console — Creazione app
Nome app: ClubManager Sport
Lingua predefinita: Italiano
Tipo: App
Categoria proposta: Sport
Prezzo: Gratis
Email supporto: supporto@clubmanagersport.it
Privacy policy URL configurata
Checklist Play Console — Store listing
Nome app
Descrizione breve
Descrizione completa
Icona app 512x512
Feature graphic
Screenshot telefono
Categoria
Contatti sviluppatore
Privacy policy
Testi store

Nome app:

ClubManager Sport

Descrizione breve:

Gestisci club, squadre, atleti, eventi, quote e comunicazioni.

Descrizione completa:

ClubManager Sport è l’app pensata per aiutare società sportive dilettantistiche a gestire in modo semplice le attività quotidiane del club.

Con ClubManager Sport puoi organizzare squadre, atleti, genitori, tutori, eventi, convocazioni, presenze, documenti, scadenze, quote associative e comunicazioni operative.

Funzioni principali:

• gestione club e ruoli
• gestione squadre
• gestione atleti
• collegamento genitori e tutori
• inviti utenti
• calendario eventi
• convocazioni
• RSVP
• registro presenze
• comunicazioni del club
• documenti e scadenze
• quote associative e pagamenti parziali
• notifiche push
• profilo utente
• preferenze notifiche
• privacy e richiesta eliminazione account
• supporto e diagnostica

L’app è progettata per supportare il lavoro quotidiano di dirigenti, allenatori, responsabili e membri autorizzati del club.

I dati sono protetti da autenticazione, ruoli, permessi e policy lato backend. Ogni utente accede solo alle informazioni per cui è autorizzato.

ClubManager Sport include anche una sezione privacy, impostazioni notifiche, documenti legali in-app e richiesta eliminazione account.

Nota: alcune funzionalità dipendono dai permessi assegnati dal club.
Checklist Play Console — App content
Privacy policy
App access
Ads
Content rating
Target audience
News apps
COVID-19 apps
Data safety
Government apps
Financial features
Health features
Account deletion
Data Safety — traccia preliminare

L’app tratta dati legati a:

Account utente
Email
Nome e cognome
Telefono opzionale
Dati club
Dati atleti
Dati tutori/genitori
Documenti
Eventi
Convocazioni
Presenze
Quote associative
Comunicazioni
Token push
Diagnostica tecnica limitata

Verificare nel form Google Play se ciascun dato è:

raccolto
condiviso
obbligatorio o facoltativo
usato per funzionalità app, comunicazioni, sicurezza o gestione account
eliminabile su richiesta
Account deletion

Percorso in-app:

Profilo utente → Impostazioni notifiche → Privacy e account → Richiedi eliminazione account

URL pubblico:

https://RosarioCensabella.github.io/clubmanager-sport-legal-pages/account-deletion.html
File da caricare su Play Console
build/app/outputs/bundle/release/app-release.aab

Non caricare:

android/key.properties
*.jks
*.keystore
Note importanti

Se l’account sviluppatore Google Play è personale e creato dopo il 13 novembre 2023, potrebbero essere richiesti passaggi di testing prima della pubblicazione in produzione.

Prima della pubblicazione finale servono asset grafici definitivi:

Icona app
Feature graphic
Screenshot store
Criteri di completamento

La fase è completata quando:

URL pubblici verificati
flutter analyze passa
flutter test passa
AAB finale generato
checklist Play Console documentata
Git pulito dopo commit