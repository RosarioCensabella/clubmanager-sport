import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/communication_repository.dart';

final communicationRepositoryProvider = Provider<CommunicationRepository>((
  ref,
) {
  return CommunicationRepository();
});
