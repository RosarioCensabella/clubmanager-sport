# ClubManager Sport — Fase 8: Autenticazione

## Obiettivo

Implementare autenticazione reale con Supabase Auth.

## Funzioni implementate

- Registrazione email/password
- Login email/password
- Recupero password
- Creazione automatica profilo utente
- Validazione form
- Gestione errori
- Routing schermate auth

## File creati

- lib/core/services/supabase_service.dart
- lib/features/auth/domain/auth_user.dart
- lib/features/auth/data/auth_repository.dart
- lib/features/auth/presentation/auth_providers.dart
- lib/features/auth/presentation/login_screen.dart
- lib/features/auth/presentation/register_screen.dart
- lib/features/auth/presentation/reset_password_screen.dart

## File modificati

- lib/main.dart
- lib/app/app_router.dart
- lib/features/welcome/presentation/welcome_screen.dart
- test/widget_test.dart

## Supabase

Configurazione richiesta:

- Email provider attivo
- Conferma email consigliata
- Site URL configurata
- Trigger `handle_new_user` già presente dalla fase database

## Comando run

```powershell
flutter run `
  --dart-define=SUPABASE_URL="https://PROJECT_REF.supabase.co" `
  --dart-define=SUPABASE_ANON_KEY="ANON_KEY"