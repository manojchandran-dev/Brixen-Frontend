import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/attendance_record.dart';
import 'attendance_state.dart';

final attendanceCubit = AttendanceCubit();

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
