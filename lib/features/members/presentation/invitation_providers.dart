import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/invitation_repository.dart';

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  return InvitationRepository();
});
