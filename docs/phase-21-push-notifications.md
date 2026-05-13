# ClubManager Sport — Fase 21: Notifiche push

## Obiettivo

Integrare notifiche push con Firebase Cloud Messaging e registrare i token dispositivo nel backend Supabase.

## Stack

- Firebase Cloud Messaging
- firebase_core
- firebase_messaging
- flutter_local_notifications
- Supabase `push_tokens`
- Supabase `notification_preferences`
- Supabase `notifications`

## Comandi principali

```powershell
flutter pub add firebase_core firebase_messaging flutter_local_notifications
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
supabase db push
dart format lib test
flutter analyze
flutter test
File creati
lib/firebase_options.dart
lib/core/services/notification_service.dart
docs/phase-21-push-notifications.md
supabase/migrations/20260511001000_push_notifications_hardening.sql
File modificati
lib/main.dart
android/app/src/main/AndroidManifest.xml
android/app/google-services.json
pubspec.yaml
pubspec.lock
Tabelle Supabase
push_tokens
notification_preferences
notifications
Funzioni implementate
inizializzazione Firebase;
background handler FCM;
richiesta permesso notifiche;
creazione canale notifiche Android;
salvataggio token FCM su Supabase;
aggiornamento token FCM;
ascolto auth state Supabase;
visualizzazione notifiche locali quando app è in foreground.
Sicurezza

RLS attiva:

ogni utente può gestire solo i propri token;
ogni utente può gestire solo le proprie preferenze;
ogni utente può leggere solo le proprie notifiche.
Test manuale Android
Avvia app.
Effettua login.
Accetta il permesso notifiche.
Verifica Supabase tabella push_tokens.
Il token deve essere salvato con:
user_id
token
platform = android
is_active = true
last_seen_at valorizzato
Note iOS

Su Windows non possiamo validare la build iOS. Prima della pubblicazione App Store serviranno:

Apple Developer Account;
configurazione APNs su Firebase;
Push Notification capability in Xcode;
test su dispositivo fisico iPhone;
eventuale download manuale di GoogleService-Info.plist dalla Firebase Console.
Errori risolti
flutterfire non trovato nel PATH;
Firebase project creato ma addFirebase falliva da CLI;
configurazione Firebase completata da progetto esistente;
flutter_local_notifications con API mista tra parametri nominati e posizionali;
cache Gradle/Kotlin/JNI corrotta risolta con clean completo;
errore Supabase Invalid API key dovuto a placeholder al posto della anon key reale.
Criteri di completamento

La fase è completata quando:

Firebase è configurato per Android;
lib/firebase_options.dart esiste;
android/app/google-services.json esiste;
supabase db push passa;
dart format lib test passa;
flutter analyze passa;
flutter test passa;
l’app parte su Android;
dopo login il token viene salvato in push_tokens;
il commit della fase è stato creato.