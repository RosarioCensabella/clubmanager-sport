# ClubManager Sport — Fase 29: Versioning app e metadati Play Store

## Obiettivo

Preparare il versioning dell’app e i contenuti base per la scheda Google Play.

## Versioning Android

Flutter usa il campo `version` in `pubspec.yaml` per valorizzare:

```text
versionName
versionCode

Formato Flutter:

version: 1.0.0+1

Dove:

1.0.0 = versione visibile agli utenti
1 = build number / versionCode Android
Regole operative

Per ogni nuova release caricata su Google Play:

versionCode deve aumentare
versionName può cambiare quando cambia la versione pubblica

Esempi:

1.0.0+1   prima release
1.0.1+2   bugfix
1.1.0+3   nuova funzione
2.0.0+4   major release
Metadati Google Play

Limiti principali:

Nome app: massimo 30 caratteri
Descrizione breve: massimo 80 caratteri
Descrizione completa: massimo 4000 caratteri
Nome app proposto
ClubManager Sport
Descrizione breve proposta
Gestisci club, squadre, atleti, eventi, quote e comunicazioni.
Descrizione completa proposta
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
Categoria proposta
Sport

Categoria alternativa:

Produttività
Target iniziale
Società sportive dilettantistiche
Dirigenti sportivi
Allenatori
Responsabili squadra
Segreterie sportive
Genitori e tutori autorizzati
Keyword operative interne
società sportiva
club sportivo
gestione squadra
gestione atleti
convocazioni
presenze
quote associative
documenti sportivi
comunicazioni club
calendario sportivo
Privacy e account

L’app contiene:

Profilo utente
Impostazioni notifiche
Privacy e account
Richiesta eliminazione account
Documenti legali
Supporto e diagnostica
Asset ancora da preparare
Icona app definitiva
Feature graphic Google Play
Screenshot telefono
Screenshot tablet opzionali
Privacy policy pubblica
Termini d’uso pubblici
Pagina web eliminazione account
Email supporto definitiva
File coinvolti
pubspec.yaml
docs/phase-29-versioning-and-play-store-metadata.md
Criteri di completamento

La fase è completata quando:

pubspec.yaml ha una versione coerente
flutter analyze passa
flutter test passa
flutter build appbundle --release passa
i metadati Play Store sono documentati
Git è pulito dopo il commit