import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/team_repository.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository();
});
