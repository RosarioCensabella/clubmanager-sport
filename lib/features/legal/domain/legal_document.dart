class LegalDocument {
  const LegalDocument({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final String id;
  final String title;
  final String subtitle;
  final String body;
}

class LegalDocuments {
  const LegalDocuments._();

  static const String privacyId = 'privacy';
  static const String termsId = 'terms';
  static const String deletionId = 'account-deletion';

  static const List<LegalDocument> all = [
    privacyPolicy,
    termsOfService,
    accountDeletion,
  ];

  static const LegalDocument privacyPolicy = LegalDocument(
    id: privacyId,
    title: 'Informativa privacy',
    subtitle: 'Come trattiamo dati personali e dati del club.',
    body: '''
ClubManager Sport tratta i dati personali necessari per fornire le funzionalità dell’app alle società sportive dilettantistiche.

Dati trattati nell’app:
- dati account, come email, nome e telefono;
- dati del club, come nome società, squadre e ruoli;
- dati atleti e tutori inseriti dal club;
- eventi, convocazioni, RSVP e presenze;
- documenti e relative scadenze;
- quote associative e stato pagamenti;
- token notifiche push, se le notifiche sono abilitate;
- richieste privacy e richieste eliminazione account.

Finalità:
- autenticazione e gestione account;
- gestione operativa del club;
- comunicazioni tra club e membri autorizzati;
- gestione documenti, eventi, presenze e quote;
- invio notifiche operative;
- sicurezza, audit e prevenzione abusi.

Accesso ai dati:
l’accesso ai dati è limitato da ruoli, permessi e policy di sicurezza lato backend. Gli utenti vedono solo i dati per cui sono autorizzati.

Notifiche:
l’utente può gestire le preferenze di notifica dalla schermata Impostazioni. Alcune comunicazioni operative importanti possono comunque essere visibili dentro l’app.

Conservazione:
i dati vengono conservati per il tempo necessario alla gestione del servizio e agli eventuali obblighi amministrativi, contabili o legali.

Eliminazione account:
l’utente può richiedere l’eliminazione account dalla sezione Privacy e account. La richiesta viene tracciata e gestita in modo sicuro.

Nota:
questa informativa in-app è una base tecnica. Prima della pubblicazione sugli store servirà una privacy policy pubblica definitiva, verificata anche dal punto di vista legale.
''',
  );

  static const LegalDocument termsOfService = LegalDocument(
    id: termsId,
    title: 'Termini d’uso',
    subtitle: 'Regole essenziali per l’utilizzo dell’app.',
    body: '''
ClubManager Sport è uno strumento digitale per supportare società sportive dilettantistiche nella gestione operativa.

Uso consentito:
- gestione club, squadre, atleti, tutori e membri;
- creazione eventi, convocazioni e presenze;
- gestione comunicazioni, documenti, scadenze e quote;
- uso dei dati solo per finalità lecite e coerenti con l’attività sportiva.

Responsabilità degli utenti:
gli utenti devono inserire informazioni corrette, aggiornate e pertinenti. Gli amministratori del club sono responsabili dei dati inseriti e della gestione dei permessi dei membri.

Account:
l’utente è responsabile della sicurezza delle proprie credenziali e dell’uso del proprio account.

Contenuti:
non è consentito caricare contenuti illeciti, offensivi, discriminatori, pericolosi o non pertinenti alle attività del club.

Disponibilità:
l’app viene fornita con l’obiettivo di offrire un servizio stabile e sicuro, ma potrebbero verificarsi manutenzioni, aggiornamenti o interruzioni tecniche.

Limitazioni:
le funzionalità amministrative, economiche e documentali dell’app non sostituiscono consulenza legale, fiscale, medica o contabile.

Nota:
questi termini in-app sono una base tecnica. Prima della pubblicazione sugli store serviranno termini d’uso pubblici definitivi, verificati anche dal punto di vista legale.
''',
  );

  static const LegalDocument accountDeletion = LegalDocument(
    id: deletionId,
    title: 'Eliminazione account',
    subtitle: 'Come richiedere la cancellazione account e dati associati.',
    body: '''
L’utente può richiedere l’eliminazione account direttamente dall’app.

Percorso in-app:
1. apri Profilo utente;
2. apri Impostazioni notifiche;
3. apri Privacy e account;
4. premi Richiedi eliminazione account;
5. inserisci un motivo facoltativo;
6. conferma la richiesta.

Cosa succede dopo la richiesta:
- viene creata una richiesta tracciata;
- la richiesta resta in stato In attesa;
- l’utente può annullarla finché è pendente;
- la cancellazione definitiva viene gestita lato backend/admin.

Perché non eliminiamo subito dal client:
la cancellazione diretta dal client non sarebbe sicura. Alcuni dati possono essere collegati a obblighi amministrativi, contabili, audit o attività del club. Per questo la richiesta viene processata in modo controllato.

Stati possibili:
- In attesa;
- Annullata;
- Completata;
- Rifiutata.

Prima della pubblicazione su Google Play servirà anche un link web pubblico per richiedere l’eliminazione account e dati associati fuori dall’app.
''',
  );

  static LegalDocument byId(String id) {
    return all.firstWhere(
      (document) => document.id == id,
      orElse: () => privacyPolicy,
    );
  }
}
