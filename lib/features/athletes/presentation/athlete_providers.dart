import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/athlete_repository.dart';

final athleteRepositoryProvider = Provider<AthleteRepository>((ref) {
  return AthleteRepository();
});
