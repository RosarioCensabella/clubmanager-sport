# ClubManager Sport — Fase 12: Gestione utenti e inviti

## Obiettivo

Implementare la gestione base degli inviti per il club attivo.

## Funzioni implementate

- Lista inviti del club
- Creazione invito
- Assegnazione ruolo
- Assegnazione squadra opzionale
- Generazione token invito
- Copia codice invito
- Revoca invito

## File creati

- lib/features/members/domain/invitation_summary.dart
- lib/features/members/domain/create_invitation_request.dart
- lib/features/members/data/invitation_repository.dart
- lib/features/members/presentation/invitation_providers.dart
- lib/features/members/presentation/invitations_screen.dart
- lib/features/members/presentation/create_invitation_screen.dart

## File modificati

- lib/features/clubs/presentation/club_context_screen.dart
- lib/app/app_router.dart

## Stati invito

- sent
- accepted
- expired
- revoked

## Ruoli invitabili

- admin
- team_manager
- coach
- parent
- athlete
- staff

## Backend

La tabella usata è:

```text
public.invitations