# ClubManager Sport — Fase 34B: Accettazione invito reale

## Obiettivo

Collegare la route `/invite/:token` a Supabase e permettere l’accettazione reale di un invito.

## Funzioni implementate

- Validazione token invito tramite Supabase.
- Visualizzazione dati invito.
- Blocco inviti scaduti, revocati, accettati o annullati.
- Creazione account con email invitata.
- Accettazione invito per utente già autenticato.
- Creazione/aggiornamento membership club.
- Aggiornamento invito a `accepted`.
- Base per flussi futuri di collegamento atleta/genitore/squadra.

## File creati

```text
lib/features/members/domain/invitation_acceptance.dart
lib/features/members/presentation/invitation_acceptance_screen.dart
docs/phase-34b-invitation-acceptance.md
supabase/migrations/20260511001400_invitation_acceptance_flow.sql
File modificati
lib/features/members/data/invitation_repository.dart
lib/features/auth/presentation/auth_providers.dart
lib/app/app_router.dart
Funzioni Supabase
get_invitation_by_token(invitation_token text)
accept_invitation(invitation_token text)
Flusso utente
1. Utente apre /invite/:token.
2. App verifica token.
3. Se token valido, mostra club, ruolo e scadenza.
4. Se utente non autenticato, crea account con email invitata.
5. Se Supabase restituisce sessione attiva, app accetta invito.
6. Se serve conferma email, utente conferma email e riapre il link.
7. Se utente già autenticato con email corretta, può accettare direttamente.
Note

La registrazione libera resta rimossa dalla UI.

La funzione accept_invitation verifica lato database:

utente autenticato;
token esistente;
stato sent;
invito non scaduto;
email autenticata uguale a email invitata.
Da completare in fasi successive
inviti specifici per genitore/tutore;
inviti specifici per atleta;
inviti coach/staff su squadra;
audit log;
permessi granulari;
email invito reale con link completo;
eventuale enforcement server-side per impedire signup fuori da invito.
Criteri di completamento

La fase è completata quando:

supabase db push passa
dart format lib test passa
flutter analyze passa
flutter test passa
/invite/:token legge Supabase
invito valido può essere accettato
Git è pulito dopo commit