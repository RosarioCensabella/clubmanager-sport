import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fee_repository.dart';

final feeRepositoryProvider = Provider<FeeRepository>((ref) {
  return FeeRepository();
});
