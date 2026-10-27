import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../employees/domain/entities/employee.dart';

/// Each salary type's colour and icon, shared by attendance, the employee
/// form and salary generation.
Color salaryTypeColor(String? type) => switch (type) {
  SalaryType.shift => AppColors.brand,
  SalaryType.piece => AppColors.positive,
  SalaryType.hourly => AppColors.brandLight,
  SalaryType.weekly => AppColors.brandDeep,
  SalaryType.monthly => AppColors.positiveDeep,
  _ => AppColors.textHint,
};

IconData salaryTypeIcon(String? type) => switch (type) {
  SalaryType.shift => Icons.schedule_rounded,
  SalaryType.piece => Icons.content_cut_rounded,
  SalaryType.hourly => Icons.timer_outlined,
  SalaryType.weekly => Icons.view_week_rounded,
  SalaryType.monthly => Icons.calendar_month_rounded,
  _ => Icons.help_outline_rounded,
};
