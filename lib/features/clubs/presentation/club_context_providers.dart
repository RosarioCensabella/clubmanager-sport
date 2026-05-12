import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/club_context_repository.dart';

final clubContextRepositoryProvider = Provider<ClubContextRepository>((ref) {
  return ClubContextRepository();
});
