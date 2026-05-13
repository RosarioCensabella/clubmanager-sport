# ClubManager Sport — Fase 35: Workspace multi-club

## Obiettivo

Trasformare la schermata club da semplice selezione a vero ingresso nel workspace gestionale del club.

## Problema risolto

Prima, cliccando su un club, l’app lo impostava come attivo ma non apriva una vera area gestionale.

Ora il flusso diventa:

```text
Login/Home → Seleziona club → Workspace club → Gestione moduli
Funzioni implementate
Schermata selezione club più chiara.
Click su club apre il workspace del club.
Nuova route /clubs/:clubId/workspace.
Nuova schermata ClubWorkspaceScreen.
Il workspace imposta automaticamente il club attivo.
Azioni gestionali aggregate nel workspace:
squadre;
atleti;
inviti/accessi;
eventi/convocazioni;
presenze;
comunicazioni;
documenti;
quote.
Visualizzazione ruolo e permessi principali.
Azione per cambiare club.
File creati
lib/features/clubs/presentation/club_workspace_screen.dart
docs/phase-35-multi-club-workspace.md
File modificati
lib/features/clubs/presentation/club_context_screen.dart
lib/app/app_router.dart
UX aggiornata

La schermata /club-context serve ora per scegliere il club.

La schermata /clubs/:clubId/workspace serve per lavorare dentro uno specifico club.

Da completare nelle prossime fasi
dettaglio/modifica/archiviazione club;
gestione membri club;
gestione permessi granulari;
dashboard differenziata admin/utente;
workspace limitato per ruolo;
gestione squadre completa;
gestione atleti completa.
Criteri di completamento

La fase è completata quando:

dart format lib test passa
flutter analyze passa
flutter test passa
cliccando su un club si apre il workspace
dal workspace si raggiungono i moduli gestionali
Git è pulito dopo commit