import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum AttendanceStatus { present, absent, leave, halfDay }

extension AttendanceStatusX on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present:  return 'Present';
      case AttendanceStatus.absent:   return 'Absent';
      case AttendanceStatus.leave:    return 'Leave';
      case AttendanceStatus.halfDay:  return 'Half Day';
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present:  return AppColors.positive;
      case AttendanceStatus.absent:   return AppColors.ink;
      case AttendanceStatus.leave:    return AppColors.brandLight;
      case AttendanceStatus.halfDay:  return AppColors.brand;
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceStatus.present:  return Icons.check_circle_rounded;
      case AttendanceStatus.absent:   return Icons.cancel_rounded;
      case AttendanceStatus.leave:    return Icons.beach_access_rounded;
      case AttendanceStatus.halfDay:  return Icons.timelapse_rounded;
    }
  }
}

class AttendanceRecord extends Equatable {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final TimeOfDay? inTime;
  final TimeOfDay? outTime;
  final AttendanceStatus status;
  final String? note;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.status,
    this.inTime,
    this.outTime,
    this.note,
  });

  AttendanceRecord copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    DateTime? date,
    TimeOfDay? inTime,
    TimeOfDay? outTime,
    AttendanceStatus? status,
    String? note,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      status: status ?? this.status,
      inTime: inTime ?? this.inTime,
      outTime: outTime ?? this.outTime,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [id, employeeId, date];
}
