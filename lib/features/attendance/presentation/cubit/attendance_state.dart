import 'package:equatable/equatable.dart';
import '../../domain/entities/attendance_record.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();
  @override
  List<Object?> get props => [];
}

class AttendanceLoaded extends AttendanceState {
  final List<AttendanceRecord> records;
  const AttendanceLoaded(this.records);

  List<AttendanceRecord> forDate(DateTime date) => records
      .where((r) =>
          r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day)
      .toList();

  @override
  List<Object?> get props => [records];
}
