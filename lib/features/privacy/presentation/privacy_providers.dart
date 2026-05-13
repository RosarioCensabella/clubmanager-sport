import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/privacy_repository.dart';

final privacyRepositoryProvider = Provider<PrivacyRepository>((ref) {
  return PrivacyRepository();
});
