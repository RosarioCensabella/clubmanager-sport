# ClubManager Sport — Fase 36: Dashboard per ruolo

## Obiettivo

Iniziare a differenziare l’esperienza del workspace club in base al ruolo dell’utente.

## Ruoli gestiti

```text
owner
admin
team_manager
coach
staff
parent
athlete
unknown
Dashboard introdotte
Dashboard gestionale completa

Per:

owner
admin

Accesso UI a:

squadre;
atleti;
inviti e accessi;
eventi;
comunicazioni;
documenti;
quote.
Dashboard operativa staff

Per:

team_manager
coach
staff

Accesso UI limitato in base al ruolo.

Esempi:

coach: eventi, squadre, atleti, comunicazioni;
staff: eventi, documenti, comunicazioni;
team manager: attività operative squadra.
Dashboard utente

Per:

parent
athlete

Accesso UI orientato alla consultazione:

eventi;
convocazioni;
comunicazioni;
documenti;
quote se previste;
impostazioni account.
File creati
lib/features/clubs/domain/club_dashboard_profile.dart
docs/phase-36-role-based-dashboard.md
File modificati
lib/features/clubs/presentation/club_workspace_screen.dart
Note importanti

Questa fase introduce una separazione UX.

La sicurezza definitiva non deve basarsi sulla UI. Le regole devono restare anche lato database, repository e RLS Supabase.

Da completare in fasi successive
permessi granulari reali;
manager con permessi scelti dall’admin;
coach limitato alle squadre assegnate;
staff limitato agli ambiti assegnati;
genitore con selezione figlio;
atleta con selezione club/squadra;
platform admin dashboard;
audit log.
Criteri di completamento

La fase è completata quando:

dart format lib test passa
flutter analyze passa
flutter test passa
owner/admin vedono dashboard gestionale
parent/athlete vedono dashboard utente
coach/staff vedono dashboard operativa
Git è pulito dopo commit