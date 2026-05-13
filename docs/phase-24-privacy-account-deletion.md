# ClubManager Sport — Fase 24: Privacy e richiesta eliminazione account

## Obiettivo

Implementare una schermata Privacy e account per permettere all’utente autenticato di richiedere o annullare l’eliminazione account.

## Funzioni implementate

- Schermata Privacy e account
- Informazioni base sul trattamento dati
- Creazione richiesta eliminazione account
- Stato richiesta eliminazione account
- Annullamento richiesta ancora pendente
- Route `/privacy`
- Collegamento da Impostazioni
- RLS Supabase per richieste appartenenti all’utente autenticato

## File creati

- lib/features/privacy/domain/account_deletion_request.dart
- lib/features/privacy/data/privacy_repository.dart
- lib/features/privacy/presentation/privacy_providers.dart
- lib/features/privacy/presentation/privacy_screen.dart
- docs/phase-24-privacy-account-deletion.md
- supabase/migrations/20260511001300_privacy_account_deletion.sql

## File modificati

- lib/app/app_router.dart
- lib/features/settings/presentation/settings_screen.dart

## Tabella Supabase

```text
public.account_deletion_requests
Campi principali
id
user_id
status
reason
requested_at
cancelled_at
completed_at
created_at
updated_at
Stati supportati
pending
cancelled
completed
rejected
Sicurezza

RLS attiva su account_deletion_requests.

Ogni utente autenticato può:

leggere solo le proprie richieste;
creare solo le proprie richieste;
aggiornare solo le proprie richieste.

È presente un vincolo unico parziale per impedire più richieste pendenti per lo stesso utente.

Nota tecnica

In schema precedenti la colonna status poteva essere un enum account_deletion_status. La migration normalizza status a text con constraint applicativa per evitare incompatibilità con valori già esistenti.

Scelta architetturale

L’app Flutter non elimina direttamente l’utente da auth.users.

La cancellazione definitiva sarà gestita lato backend/admin in una fase successiva, così da:

rispettare obblighi amministrativi;
gestire dati collegati a club, quote, presenze e audit;
evitare operazioni privilegiate dal client;
mantenere tracciabilità.
Test manuale
Effettuare login.
Aprire Profilo utente.
Aprire Impostazioni notifiche.
Aprire Privacy e account.
Creare una richiesta di eliminazione account.
Verificare in Supabase account_deletion_requests:
user_id valorizzato;
status = pending;
requested_at valorizzato.
Annullare la richiesta.
Verificare in Supabase:
status = cancelled;
cancelled_at valorizzato.
Criteri di completamento

La fase è completata quando:

supabase db push passa;
dart format lib test passa;
flutter analyze passa;
flutter test passa;
la schermata Privacy e account si apre;
la richiesta eliminazione account viene creata;
la richiesta eliminazione account viene annullata;
il commit della fase è stato creato.