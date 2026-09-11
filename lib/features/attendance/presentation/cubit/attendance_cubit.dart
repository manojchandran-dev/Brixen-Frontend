import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/attendance_record.dart';
import 'attendance_state.dart';

final attendanceCubit = AttendanceCubit();

// No repository layer yet — this feature has no backend datasource at all
// (pure in-memory Cubit, and the feature is currently disabled in the
// bottom nav). Add one only when a real attendance_remote_datasource.dart
// exists to wrap.
class AttendanceCubit extends Cubit<AttendanceState> {
  final List<AttendanceRecord> _records = [];

  AttendanceCubit() : super(const AttendanceLoaded([]));

  void add(AttendanceRecord record) {
    _records.add(record);
    emit(AttendanceLoaded(List.from(_records)));
  }

  void update(AttendanceRecord record) {
    final idx = _records.indexWhere((r) => r.id == record.id);
    if (idx >= 0) {
      _records[idx] = record;
      emit(AttendanceLoaded(List.from(_records)));
    }
  }

  void delete(String id) {
    _records.removeWhere((r) => r.id == id);
    emit(AttendanceLoaded(List.from(_records)));
  }
}
