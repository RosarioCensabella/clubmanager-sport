# ClubManager Sport — Fase 13: Gestione atleti e genitori/tutori

## Obiettivo

Implementare la gestione atleti e il collegamento genitori/tutori.

## Fase 13A implementata

- Lista atleti del club attivo
- Stato vuoto atleti
- Creazione atleta
- Associazione opzionale a squadra
- Stato certificato medico
- Scadenza certificato medico
- Numero maglia
- Ruolo sportivo
- Note staff private

## Fase 13B implementata

- Dettaglio atleta
- Lista genitori/tutori collegati
- Collegamento genitore/tutore tramite email
- Rimozione collegamento genitore/tutore
- Navigazione lista atleti > dettaglio atleta

## File creati

- lib/features/athletes/domain/athlete_summary.dart
- lib/features/athletes/domain/create_athlete_request.dart
- lib/features/athletes/domain/parent_relation_summary.dart
- lib/features/athletes/data/athlete_repository.dart
- lib/features/athletes/presentation/athlete_providers.dart
- lib/features/athletes/presentation/athletes_screen.dart
- lib/features/athletes/presentation/create_athlete_screen.dart
- lib/features/athletes/presentation/athlete_detail_screen.dart
- lib/features/athletes/presentation/link_parent_screen.dart

## File modificati

- lib/app/app_router.dart
- lib/features/clubs/presentation/club_context_screen.dart

## Tabelle usate

- public.athlete_profiles
- public.team_memberships
- public.parent_athlete_relations
- public.profiles

## Dati sanitari

La versione 1.0 minimizza i dati sanitari.

Per il certificato medico vengono gestiti:

- stato;
- data scadenza.

Il caricamento file verrà gestito più avanti nella fase documenti.

## Note staff

Le note staff sono private e non devono essere mostrate nelle schermate per genitori o atleti.

## Genitori/Tutori

Il collegamento avviene tramite email di un utente già registrato e già visibile nel club.

Se il genitore/tutore non esiste ancora:

1. creare invito con ruolo parent;
2. attendere registrazione;
3. collegare al profilo atleta.

## Sicurezza

Le relazioni genitore/atleta sono protette da RLS.

Il genitore vede solo gli atleti collegati.

Staff autorizzato può creare o rimuovere relazioni.

## Test manuale

1. Effettuare login.
2. Selezionare club attivo.
3. Aprire Gestisci atleti.
4. Creare atleta se non esiste.
5. Aprire dettaglio atleta.
6. Verificare lista genitori/tutori vuota.
7. Collegare un genitore/tutore tramite email.
8. Verificare che appaia nella lista.
9. Rimuovere il collegamento.
10. Verificare su Supabase la tabella `parent_athlete_relations`.

## Criteri di completamento Fase 13

La fase è completata quando:

- la lista atleti funziona;
- la creazione atleta funziona;
- l'associazione alla squadra funziona;
- il dettaglio atleta funziona;
- il collegamento genitore/tutore funziona;
- la rimozione collegamento funziona;
- `dart format lib test` passa;
- `flutter analyze` passa;
- `flutter test` passa;
- il commit della fase è stato creato.