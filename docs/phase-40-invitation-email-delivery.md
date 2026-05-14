# Phase 40 — Invitation delivery, deep links and acceptance flow

## Stato

Completata.

La fase 40 ha stabilizzato il flusso completo degli inviti:

- creazione invito da admin club
- generazione link invito
- invio email tramite Supabase Edge Function e Resend
- copia manuale link/codice invito
- apertura invito da link o codice
- registrazione account solo tramite invito
- persistenza invito pendente dopo verifica email/login
- accettazione invito e associazione automatica al club
- associazione eventuale a squadra/atleta
- gestione errori email
- ricerca/filtro inviti
- revoca e cancellazione invito revocato

---

## Obiettivo prodotto

L’app non deve permettere registrazione libera.

Un utente deve entrare nella piattaforma solo se riceve un invito da un club o dalla piattaforma. L’invito definisce:

- club di appartenenza
- ruolo
- eventuale squadra
- eventuale atleta collegato
- stato dell’invito
- validità temporale

Il flusso deve funzionare anche quando:

- il link email non apre direttamente l’app
- l’utente copia manualmente il codice
- l’utente crea l’account e deve prima confermare la mail
- dopo login l’app deve recuperare l’invito pendente
- l’utente non ha ancora club collegati

---

## Modifiche principali

### 1. Invio email inviti

È stata aggiunta la gestione dell’invio email invito tramite Supabase Edge Function.

La sezione inviti ora mostra:

- stato invito
- validità invito
- stato email
- ultimo errore email
- link invito
- azione copia link
- azione invia email
- azione revoca
- azione elimina dopo revoca

La gestione email supporta gli errori più comuni di Resend:

- dominio mittente non verificato
- modalità test Resend
- `RESEND_API_KEY` mancante
- errore generico provider

Nota: senza dominio verificato su Resend, è possibile inviare email solo all’indirizzo proprietario dell’account Resend oppure usando le condizioni consentite dal provider in modalità test.

---

### 2. Link invito

Il link invito viene costruito con base configurabile:

```dart
INVITATION_BASE_URL

Default:

clubmanager-sport://app/invite

Esempio link:

clubmanager-sport://app/invite/<TOKEN>

L’app supporta anche l’inserimento manuale di:

solo token
link completo
link con path /invite/<TOKEN>
link con query ?token=<TOKEN>
3. Deep link Android

È stato aggiornato:

android/app/src/main/AndroidManifest.xml

per permettere all’app Android di ricevere i link custom scheme.

Il flusso deep link resta comunque affiancato da un fallback manuale: l’utente può sempre copiare il codice/link e inserirlo dal login o dalla schermata “Nessun club collegato”.

4. Login con codice invito

È stato aggiornato:

lib/features/auth/presentation/login_screen.dart

Il login ora include una card:

Hai ricevuto un invito?

Da lì l’utente può:

aprire il link ricevuto via email
incollare il codice invito
incollare l’intero link invito

Quando viene inserito un codice valido, il token viene salvato come invito pendente e l’app apre la schermata di accettazione invito.

5. Persistenza invito pendente

È stato aggiornato:

lib/features/members/data/invitation_repository.dart

Sono state aggiunte funzioni per:

salvare il token invito pendente
leggere il token pendente
cancellare il token dopo accettazione
estrarre il token da codice o link
costruire il link invito

Questo serve per gestire il caso in cui l’utente:

apre l’invito
crea un account
deve confermare la mail
torna al login
accede
viene riportato automaticamente all’invito
6. Accettazione invito

È stata aggiornata:

lib/features/members/presentation/invitation_acceptance_screen.dart

La schermata ora gestisce:

invito valido
invito scaduto
invito revocato
invito già accettato
account già connesso
email account diversa da email invito
creazione account da invito
accettazione dopo login

Se l’utente è già loggato con la mail corretta, può accettare direttamente.

Se l’utente non è loggato, può creare account dalla schermata invito.

Se la conferma email è richiesta, il token viene conservato e ripreso dopo il login.

7. Schermata “Nessun club collegato”

È stata aggiornata:

lib/features/clubs/presentation/club_context_screen.dart

Quando un utente è autenticato ma non ha club collegati, la schermata mostra ora:

messaggio esplicativo
pulsante “Accetta invito”
pulsante profilo utente
pulsante crea club

Il pulsante “Accetta invito” apre un dialog dove inserire token o link.

Dopo l’inserimento, l’app apre la schermata di accettazione invito.

È stata corretta anche una crash condition Flutter legata alla navigazione subito dopo la chiusura del dialog.

8. Funzioni database Supabase

È stata aggiunta la migration:

supabase/migrations/20260511001810_fix_invitation_acceptance.sql

La migration aggiorna/ricrea:

public.get_invitation_by_token(text)
public.accept_invitation(text)

La funzione accept_invitation ora:

verifica che l’utente sia autenticato
verifica che il token esista
verifica che l’email dell’utente corrisponda all’email invitata
verifica stato e scadenza invito
crea/aggiorna club_memberships
collega eventuale athlete_profile
crea/aggiorna eventuale team_memberships
marca l’invito come accepted
salva accepted_by
rende l’accettazione idempotente per lo stesso utente

Questo ha risolto il problema in cui l’utente riusciva a creare l’account ma restava su:

Nessun club collegato
File modificati
Flutter
android/app/src/main/AndroidManifest.xml
lib/app/app_router.dart
lib/features/auth/data/auth_repository.dart
lib/features/auth/presentation/auth_callback_screen.dart
lib/features/auth/presentation/login_screen.dart
lib/features/clubs/presentation/club_context_screen.dart
lib/features/members/data/invitation_repository.dart
lib/features/members/domain/invitation_summary.dart
lib/features/members/presentation/create_invitation_screen.dart
lib/features/members/presentation/invitation_acceptance_screen.dart
lib/features/members/presentation/invitations_screen.dart
Supabase
supabase/functions/send-invitation-email/
supabase/migrations/20260511001800_invitation_email_delivery.sql
supabase/migrations/20260511001810_fix_invitation_acceptance.sql
Documentazione
docs/phase-40-invitation-email-delivery.md
Problemi incontrati e risolti
1. Resend non inviava email a indirizzi diversi

Errore:

You can only send testing emails to your own email address

Causa:

Resend era in modalità test o senza dominio verificato.

Soluzione temporanea:

testare verso l’email proprietaria dell’account Resend
mostrare messaggio errore comprensibile nell’app

Soluzione definitiva futura:

verificare dominio su Resend
usare mittente del dominio verificato
2. Dominio mittente non verificato

Errore:

The gmail.com domain is not verified

Causa:

Non si può usare un indirizzo Gmail come mittente personalizzato in Resend senza verifica dominio.

Soluzione:

usare mittente consentito per test
oppure verificare dominio proprio
3. Link invito non apriva app

Causa:

deep link custom scheme non completamente configurato
necessità di fallback manuale

Soluzione:

aggiornato AndroidManifest
aggiunto inserimento manuale codice/link nel login
aggiunto inserimento manuale codice/link nella schermata “Nessun club collegato”
4. Account creato ma non associato al club

Causa:

La funzione accept_invitation non stava creando correttamente la membership club o non veniva richiamata dopo conferma/login.

Soluzione:

salvataggio token invito pendente
ripresa invito dopo login
nuova funzione database accept_invitation
creazione automatica club_memberships
test manuale positivo
5. Errore migration duplicate

Errore:

duplicate key value violates unique constraint "schema_migrations_pkey"
Key (version)=(20260511001800) already exists

Causa:

Due migration locali avevano lo stesso timestamp:

20260511001800_fix_invitation_acceptance.sql
20260511001800_invitation_email_delivery.sql

Soluzione:

eliminata/rinominata la migration duplicata
creato nuovo timestamp:
20260511001810_fix_invitation_acceptance.sql
6. Errore Postgres su funzione già esistente

Errore:

cannot change return type of existing function

Causa:

Postgres non permette di cambiare il return type di una funzione con create or replace function.

Soluzione:

La migration ora fa:

drop function if exists public.get_invitation_by_token(text);
drop function if exists public.accept_invitation(text);

prima di ricreare le funzioni.

7. Crash Flutter dopo incolla invito

Errore:

'_children.contains(child)': is not true

Causa probabile:

Navigazione subito dopo chiusura dialog, durante aggiornamento dell’albero widget.

Soluzione:

dialog senza controller persistente
navigazione con WidgetsBinding.instance.addPostFrameCallback
test manuale positivo
Test automatici eseguiti

Comandi:

dart format lib test
flutter analyze
flutter test
supabase migration list

Risultati:

Formatted 127 files (0 changed)
No issues found
All tests passed
20260511001810 presente sia in Local sia in Remote
Test manuali eseguiti
Test 1 — Invio email in modalità consentita

Esito:

Email arrivata correttamente a cen.ros98@gmail.com
Test 2 — Apertura invito manuale

Procedura:

Login con account invitato
Schermata “Nessun club collegato”
Click su “Accetta invito”
Incolla token/link invito
Continua
Apertura schermata accettazione invito

Esito:

Funziona
Test 3 — Accettazione invito e associazione club

Procedura:

Account atleta creato da invito
Conferma email
Login
Inserimento invito
Accettazione invito

Esito:

Associazione al club funzionante
Stato finale

La fase 40 è completata.

Il flusso inviti ora è utilizzabile anche senza deep link perfetto, perché il fallback manuale tramite codice/link è presente sia nel login sia nella schermata “Nessun club collegato”.

Il problema principale di associazione utente-club è stato risolto.

Limiti noti
Email verso indirizzi diversi

Per inviare email a qualsiasi destinatario tramite Resend serve un dominio verificato.

Fino a quando non viene verificato un dominio:

si può testare solo con gli indirizzi consentiti dal provider
l’app mostra gli errori in modo leggibile
il link/codice può comunque essere copiato manualmente e inviato fuori app
Deep link email

Il deep link custom scheme può dipendere dal client email, dal sistema operativo e dall’ambiente di test.

Per questo resta necessario mantenere il fallback:

Login > Hai ricevuto un invito? > Inserisci codice invito

e:

Nessun club collegato > Accetta invito