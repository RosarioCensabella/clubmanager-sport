# ClubManager Sport — Fase 34A: Autenticazione solo da invito

## Obiettivo

Rimuovere la registrazione libera e preparare il flusso di accesso solo tramite invito.

## Decisione prodotto

ClubManager Sport non permette registrazione libera.

Gli account vengono creati o collegati solo tramite invito inviato dal club owner/admin.

## Modifiche implementate

- Rimosso pulsante “Crea account” dalla schermata Welcome.
- Rimosso pulsante “Crea nuovo account” dalla schermata Login.
- Aggiunto messaggio esplicativo: serve invito del club.
- `/register` non permette più registrazione libera.
- Aggiunta route `/invite/:token`.
- `RegisterScreen` supporta modalità con token invito.
- Preparata base UI per il flusso invito.

## File modificati

```text
lib/features/welcome/presentation/welcome_screen.dart
lib/features/auth/presentation/login_screen.dart
lib/features/auth/presentation/register_screen.dart
lib/app/app_router.dart
Flusso attuale
Welcome → Login

Se l’utente non ha account:

Deve ricevere un link invito dal club

Se apre:

/register

vede schermata informativa che blocca la registrazione libera.

Se apre:

/invite/:token

vede la schermata invito con token ricevuto.

Da completare nella Fase 34B
validazione token invito da Supabase;
schermata accetta invito completa;
creazione account da invito;
collegamento account a club;
collegamento account a squadra/atleta/genitore se previsto;
stato invito accepted;
scadenza invito;
revoca invito;
audit log invito accettato.
Criteri di completamento

La fase è completata quando:

dart format lib test passa
flutter analyze passa
flutter test passa
non esiste più accesso UI alla registrazione libera
/register è bloccata
/invite/:token è raggiungibile
Git è pulito dopo commit