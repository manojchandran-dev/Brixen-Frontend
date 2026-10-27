import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/attendance_remote_datasource.dart';
import '../domain/attendance.dart';

/// The admin screen's query: a day (null = today in the company's zone),
/// search text, and kind (SHIFT_RATE / PIECE_RATE / null = both).
typedef AttendanceQuery = ({String? date, String search, String? kind});

/// One day's attendance for the admin screen. Saving or deleting a record
/// invalidates the whole family, so every open day refreshes.
final attendanceDayProvider = FutureProvider.autoDispose
    .family<AttendanceList, AttendanceQuery>(
      (ref, q) => ref
          .read(attendanceDatasourceProvider)
          .list(date: q.date, search: q.search, kind: q.kind),
    );

/// The signed-in employee's own profile.
final myEmployeeProvider = FutureProvider.autoDispose(
  (ref) => ref.read(attendanceDatasourceProvider).myEmployee(),
);

/// The signed-in employee's attendance for a month ("YYYY-MM"; null = this
/// month so far).
final myAttendanceProvider = FutureProvider.autoDispose
    .family<MyAttendance, String?>((ref, month) {
      if (month == null) {
        return ref.read(attendanceDatasourceProvider).myAttendance();
      }
      final y = int.parse(month.substring(0, 4));
      final m = int.parse(month.substring(5, 7));
      final last = DateTime(y, m + 1, 0).day;
      return ref
          .read(attendanceDatasourceProvider)
          .myAttendance(
            from: '$month-01',
            to: '$month-${last.toString().padLeft(2, '0')}',
          );
    });
