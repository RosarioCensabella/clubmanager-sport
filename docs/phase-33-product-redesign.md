# ClubManager Sport — Fase 33: Product redesign, ruoli, accessi e workspace

## Obiettivo

Ridefinire l’app come gestionale multi-club con accessi controllati, dashboard separate, inviti, permessi granulari, archiviazione, revoca accessi e audit log.

Questa fase è decisionale e architetturale. Serve a bloccare le scelte prima di modificare codice, database e UX.

---

## Ruoli principali

I ruoli principali della piattaforma sono:

```text
utente
platform_admin
club_owner_admin
1. Utente

È l’account base.

Un utente può essere:

genitore/tutore;
atleta;
allenatore;
membro staff;
manager;
segreteria;
membro semplice;
altro profilo operativo.

L’utente non ha poteri globali sulla piattaforma.

I permessi reali dipendono dai club, squadre, atleti e ruoli a cui viene collegato tramite invito o assegnazione.

2. Platform admin

Gestisce la piattaforma.

Può:

creare club;
approvare club;
vedere richieste globali;
vedere richieste eliminazione account;
gestire configurazioni globali;
supportare club e utenti;
consultare audit log globali;
intervenire su problemi tecnici/amministrativi.

Non è il ruolo normale di gestione quotidiana del club.

3. Club owner/admin

Gestisce solo i propri club.

Può:

gestire dati del club;
gestire squadre;
gestire atleti;
gestire genitori/tutori;
gestire staff;
invitare utenti;
assegnare ruoli;
assegnare permessi;
revocare accessi;
archiviare elementi del club;
consultare audit log del club.

L’admin del club è il soggetto principale che manda gli inviti.

Web gestionale e app mobile

L’app deve funzionare anche da web/PC per chi gestisce i club.

Web / PC

Destinato a:

platform admin;
club owner/admin;
manager;
segreteria;
allenatori;
staff autorizzato.

Funzioni principali web:

dashboard gestionale;
gestione club;
gestione squadre;
gestione atleti;
gestione inviti;
gestione ruoli e permessi;
documenti;
quote;
comunicazioni;
eventi;
presenze;
audit log.
App mobile

Destinata soprattutto a:

genitori/tutori;
atleti;
allenatori;
staff operativo;
utenti normali.

Funzioni principali mobile:

consultazione dati personali;
selezione figlio/atleta;
convocazioni;
RSVP;
eventi;
presenze visibili;
documenti;
quote;
comunicazioni;
notifiche;
profilo;
privacy/account.
Accesso web per utente semplice

Se un utente semplice accede da web e non ha permessi gestionali, deve vedere una dashboard limitata o un messaggio:

Questo profilo è pensato per l’utilizzo da app mobile.

La sicurezza non deve basarsi solo sulla UI. I permessi devono essere sempre controllati anche lato Supabase/RLS.

Dashboard

Servono dashboard diverse.

Dashboard platform admin

Mostra:

club presenti;
richieste approvazione club;
richieste eliminazione account;
utenti globali;
audit log globale;
stato sistema;
supporto;
configurazioni piattaforma.
Dashboard gestionale club

Per club owner/admin, manager, coach e staff autorizzato.

Mostra:

club attivo;
squadre;
atleti;
membri;
inviti;
eventi;
convocazioni;
presenze;
documenti;
quote;
comunicazioni;
audit log;
impostazioni club.

La dashboard deve adattarsi ai permessi.

Esempio: un coach vede solo squadre/eventi/convocazioni/presenze per le squadre assegnate.

Dashboard utente

Per genitori, atleti e utenti semplici.

Mostra:

profilo selezionato;
figlio/atleta selezionato se presente;
club/squadra selezionata se presente;
prossimi eventi;
convocazioni;
RSVP;
comunicazioni;
documenti richiesti;
quote;
profilo;
impostazioni;
privacy/account.
Workspace multi-club

Non bisogna mostrare tutti i club come una lista piatta da gestire indistintamente.

Flusso corretto:

Home
→ selezione contesto
→ club attivo
→ workspace del club
→ gestione moduli del club
Utente con più club

Se un utente ha accesso a più club, deve scegliere il club su cui lavorare.

Allenatore con più club/squadre

Deve poter scegliere:

club → squadra → gestione operativa
Manager/staff con più club

Deve poter scegliere:

club → area autorizzata
Genitore con più figli

Deve poter scegliere:

figlio → club/squadra → dati collegati
Atleta con più squadre o club

Deve poter scegliere:

club/squadra → eventi, convocazioni, documenti, comunicazioni
Registrazione e inviti

La registrazione libera deve essere rimossa.

Nuovo modello
Login: sempre disponibile
Registrazione libera: non disponibile
Registrazione da invito: disponibile solo tramite link/token
Inviti

Il club owner/admin può invitare utenti.

Un invito può definire:

email invitata;
club;
ruolo operativo;
permessi;
squadra collegata;
atleta collegato;
relazione genitore/tutore;
scadenza;
stato;
token invito.
Stati invito
draft
sent
accepted
expired
revoked
cancelled
Flusso invito
1. Admin club crea invito.
2. Sistema genera token/link.
3. Utente riceve link.
4. Utente apre link.
5. Se non ha account, crea credenziali tramite invito.
6. Se ha già account, accetta invito.
7. Sistema collega account a club/squadra/atleta/permessi.
8. Audit log registra l’operazione.
Collegamento atleta ad account

L’atleta anagrafico non deve registrarsi liberamente e scegliersi un club.

Flusso corretto:

1. Admin crea atleta anagrafico.
2. Admin invita atleta o genitore/tutore.
3. Invito contiene athlete_profile_id o parent_relation.
4. Utente accetta invito.
5. Account viene collegato all’atleta.
Genitore/tutore

Un genitore può essere collegato a uno o più atleti.

Ogni relazione deve indicare:

atleta;
tipo relazione;
autorizzazioni;
stato;
club;
eventuali note.
Atleta con account proprio

Un atleta può avere account proprio se il club lo invita.

L’account atleta vede solo dati consentiti:

eventi;
convocazioni;
RSVP;
comunicazioni;
documenti personali;
quote se consentito;
profilo.
Permessi granulari

Il ruolo operativo non basta. Servono permessi granulari.

Esempi:

can_view_dashboard
can_manage_club
can_manage_teams
can_manage_members
can_invite_users
can_manage_athletes
can_manage_parent_relations
can_manage_events
can_manage_callups
can_manage_attendance
can_manage_documents
can_manage_fees
can_manage_communications
can_manage_roles
can_manage_permissions
can_archive_records
can_revoke_access
can_view_audit_log
can_manage_settings
Manager

Un manager può avere permessi scelti dall’admin del club.

Esempio:

manager quote:
- can_manage_fees
- can_view_athletes
- can_view_members

manager segreteria:
- can_manage_documents
- can_manage_members
- can_invite_users

manager sportivo:
- can_manage_teams
- can_manage_athletes
- can_manage_events
Coach

Un coach può essere assegnato a una o più squadre.

Può avere permessi limitati alle squadre assegnate.

Esempio:

can_view_team_athletes
can_manage_team_events
can_manage_callups
can_manage_attendance
can_send_team_communications
Staff

Lo staff può avere permessi specifici per club, squadra o area operativa.

Archiviazione, eliminazione e revoca

Per i dati principali non si deve eliminare fisicamente subito.

Archiviazione

Usare archiviazione/disattivazione per:

club;
squadre;
atleti;
eventi;
comunicazioni;
documenti;
quote;
relazioni genitori/tutori.

Campi possibili:

archived_at
archived_by
archive_reason

Oppure, dove già presente:

deleted_at
Togliere dall’app

Quando l’admin vuole “togliere” un elemento dall’app, il comportamento deve essere:

archivia/disattiva
nascondi dalle liste operative
mantieni storico
mantieni audit
Revoca accesso

Per gli utenti non basta archiviare.

Serve una funzione:

Revoca accesso

Applicabile a:

genitore;
atleta;
coach;
manager;
staff;
membro.

Effetti:

membership disattivata;
permessi rimossi;
token invito revocati;
sessioni future non autorizzate;
dati storici conservati;
audit log registrato.

Campi possibili:

access_status
revoked_at
revoked_by
revocation_reason

Stati accesso:

active
invited
suspended
revoked
archived
Stato account

Ogni account/membership deve avere stato chiaro.

Stati account globali:

active
disabled
pending_deletion
deleted

Stati membership club:

invited
active
suspended
revoked
archived

Stati invito:

sent
accepted
expired
revoked
cancelled

Stati relazione genitore/atleta:

active
revoked
archived
Audit log

Serve una funzione audit log.

Obiettivo

Registrare le azioni importanti.

Esempi:

utente creato
invito creato
invito accettato
permessi modificati
club modificato
squadra creata/modificata/archiviata
atleta creato/modificato/archiviato
genitore collegato
accesso revocato
evento creato/modificato/archiviato
convocazione modificata
presenza modificata
quota creata/modificata/pagata
documento caricato/modificato/archiviato
comunicazione inviata
richiesta eliminazione account creata/annullata/completata
Campi audit log
id
actor_user_id
club_id
target_type
target_id
action
metadata
created_at
ip_address opzionale
user_agent opzionale
Visibilità audit

Platform admin:

vede audit globale

Club owner/admin:

vede audit dei propri club

Manager/staff:

vede audit solo se ha permesso can_view_audit_log

Utente semplice:

non vede audit log
CRUD mancanti urgenti
Club

Servono:

dettaglio club
modifica club
archivia club
gestione membri
gestione inviti
gestione permessi
audit club
Squadre

Servono:

dettaglio squadra
modifica squadra
archivia squadra
assegna allenatori
assegna staff
assegna atleti
audit squadra
Atleti

Servono:

dettaglio atleta completo
modifica atleta
archivia atleta
collega genitore/tutore
collega account atleta
assegna squadra
storico documenti
storico quote
storico presenze
storico eventi
audit atleta
UX da migliorare

Problemi attuali:

liste troppo operative ma poco gestionali
elementi creati non sempre apribili/modificabili
contesto club poco chiaro
ruoli non abbastanza visibili
flusso inviti non abbastanza esplicito
registrazione libera da rimuovere
dashboard non differenziate

Obiettivi UX:

Home chiara
workspace per club
dashboard per ruolo
azioni principali evidenti
stati vuoti utili
messaggi errore comprensibili
conferme per azioni sensibili
archivia/revoca invece di elimina brutale