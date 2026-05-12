import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_repository.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});
