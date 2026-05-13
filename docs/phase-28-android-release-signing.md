# ClubManager Sport — Fase 28: Firma Android release e preparazione Play Store

## Obiettivo

Configurare la firma Android release e generare un Android App Bundle pronto per il caricamento su Google Play Console.

## Risultato

Generato correttamente:

```text
build/app/outputs/bundle/release/app-release.aab

Dimensione rilevata:

47.0 MB
File creati localmente ma non committati
android/key.properties

Il file contiene password e percorso del keystore. È ignorato da Git tramite:

android/.gitignore
File esterno al progetto
C:\Users\RosarioCensabella\clubmanager-keystores\clubmanager-sport-upload.jks

Questo file è il keystore di upload Android.

Deve essere conservato in modo sicuro insieme a:

keystore password;
key password;
alias.

Alias usato:

clubmanager-sport-upload
File modificati
android/app/build.gradle.kts
Configurazioni Gradle aggiunte
lettura android/key.properties;
signing config release;
firma release con keystore esterno;
Java 17;
desugaring;
multidex;
build release pronta per appbundle.
Comandi usati

Creazione cartella keystore:

New-Item -ItemType Directory -Force "$env:USERPROFILE\clubmanager-keystores"

Creazione keystore:

& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair `
  -v `
  -keystore "$env:USERPROFILE\clubmanager-keystores\clubmanager-sport-upload.jks" `
  -storetype JKS `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias clubmanager-sport-upload

Build AAB:

flutter build appbundle --release `
  --dart-define=SUPABASE_URL="https://cdsofqeywjbatghgladc.supabase.co" `
  --dart-define=SUPABASE_ANON_KEY="LA_TUA_ANON_KEY"

Verifica output:

Test-Path build\app\outputs\bundle\release\app-release.aab
Get-Item build\app\outputs\bundle\release\app-release.aab | Select-Object Name, Length, LastWriteTime
Output verificato
app-release.aab
49289251 bytes
Controlli superati
dart format lib test
flutter analyze
flutter test
flutter build appbundle --release
Sicurezza

Non committare mai:

android/key.properties
*.jks
*.keystore

Il keystore non deve essere perso: senza questa chiave potresti avere problemi a pubblicare aggiornamenti futuri dell’app.

Criteri di completamento

La fase è completata quando:

android/key.properties è ignorato da Git;
il keystore .jks esiste fuori dal repository;
flutter analyze passa;
flutter test passa;
flutter build appbundle --release passa;
app-release.aab viene generato;
Git è pulito dopo il commit.