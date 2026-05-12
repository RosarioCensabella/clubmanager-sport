import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});
