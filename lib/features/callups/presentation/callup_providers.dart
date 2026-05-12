import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/callup_repository.dart';

final callupRepositoryProvider = Provider<CallupRepository>((ref) {
  return CallupRepository();
});
