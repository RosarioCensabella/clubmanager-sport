# ClubManager Sport — Fase 13: Gestione atleti e genitori/tutori

## Obiettivo

Implementare la gestione atleti e, nella sotto-fase successiva, il collegamento genitori/tutori.

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

## File creati

- lib/features/athletes/domain/athlete_summary.dart
- lib/features/athletes/domain/create_athlete_request.dart
- lib/features/athletes/data/athlete_repository.dart
- lib/features/athletes/presentation/athlete_providers.dart
- lib/features/athletes/presentation/athletes_screen.dart
- lib/features/athletes/presentation/create_athlete_screen.dart

## File modificati

- lib/app/app_router.dart
- lib/features/clubs/presentation/club_context_screen.dart

## Tabelle usate

- public.athlete_profiles
- public.team_memberships

## Dati sanitari

La versione 1.0 minimizza i dati sanitari.

Per il certificato medico vengono gestiti:

- stato;
- data scadenza.

Il caricamento file verrà gestito più avanti nella fase documenti.

## Note staff

Le note staff sono private e non devono essere mostrate nelle schermate per genitori o atleti.

## Fase 13B da fare

- Dettaglio atleta
- Lista genitori/tutori collegati
- Collegamento genitore/tutore
- Rimozione relazione
- Validazioni privacy
- Controlli permessi

## Test manuale

1. Effettuare login.
2. Selezionare club attivo.
3. Aprire Gestisci atleti.
4. Verificare stato vuoto.
5. Creare atleta.
6. Collegare atleta a una squadra se presente.
7. Verificare ritorno alla lista.
8. Verificare atleta visibile.
9. Verificare riga su Supabase in `athlete_profiles`.
10. Se collegato a squadra, verificare riga in `team_memberships`.

## Criteri di completamento Fase 13A

La sotto-fase è completata quando:

- la lista atleti funziona;
- la creazione atleta funziona;
- l'associazione alla squadra funziona;
- `dart format lib test` passa;
- `flutter analyze` passa;
- `flutter test` passa;
- il commit della sotto-fase è stato creato.