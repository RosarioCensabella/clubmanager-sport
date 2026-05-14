# ClubManager Sport — Fase 40: Invio email inviti

## Obiettivo

Inviare realmente via email gli inviti creati dagli admin del club.

## Implementazione

- Supabase Edge Function `send-invitation-email`.
- Provider email configurato tramite secret `RESEND_API_KEY`.
- Invio email dopo creazione invito.
- Reinvia email da lista inviti.
- Copia link invito.
- Tracciamento invio:
  - `email_sent_at`
  - `email_last_error`
  - `email_send_attempts`

## Secrets richiesti

```text
RESEND_API_KEY
INVITATION_FROM_EMAIL
APP_INVITE_BASE_URL
Sicurezza

La chiave API email resta su Supabase Edge Functions e non viene mai inserita nel codice Flutter.

La funzione consente l’invio solo ad account con membership owner o admin nel club.

Test
supabase db push
supabase functions deploy send-invitation-email
dart format lib test
flutter analyze
flutter test
creazione invito con email reale
reinvia email da lista inviti
revoca invito
copia link invito