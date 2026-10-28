import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';

/// Pick a month: the year with arrows, then its twelve months. Months after
/// [last] (default: this month) can't be picked. Returns the 1st of the
/// month picked, or null.
Future<DateTime?> showMonthPicker(
  BuildContext context, {
  required DateTime initial,
  DateTime? last,
}) {
  final end = last ?? DateTime(DateTime.now().year, DateTime.now().month);
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _MonthPickerDialog(
      initial: DateTime(initial.year, initial.month),
      last: DateTime(end.year, end.month),
    ),
  );
}

class _MonthPickerDialog extends StatefulWidget {
  final DateTime initial, last;
  const _MonthPickerDialog({required this.initial, required this.last});

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year = widget.initial.year;

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData icon, VoidCallback? onTap) =>
        IconButton(onPressed: onTap, icon: Icon(icon), color: AppColors.brand);
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                arrow(
                  Icons.chevron_left_rounded,
                  () => setState(() => _year--),
                ),
                Expanded(
                  child: Text(
                    '$_year',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                arrow(
                  Icons.chevron_right_rounded,
                  _year >= widget.last.year
                      ? null
                      : () => setState(() => _year++),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: [
                for (var m = 1; m <= 12; m++)
                  _MonthCell(
                    label: DateFormat('MMM').format(DateTime(_year, m)),
                    selected:
                        _year == widget.initial.year &&
                        m == widget.initial.month,
                    enabled: !DateTime(_year, m).isAfter(widget.last),
                    onTap: () => Navigator.of(context).pop(DateTime(_year, m)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final String label;
  final bool selected, enabled;
  final VoidCallback onTap;
  const _MonthCell({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : 0.35,
    child: GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.brand, AppColors.brandDeep],
                )
              : null,
          color: selected ? null : AppColors.brand.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}
