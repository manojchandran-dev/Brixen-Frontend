import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The date-picker trigger box that was duplicated (byte-for-byte in
/// places) across Sales/Purchases/Expenses/Employees' create forms — a tap
/// opens the platform's [showDatePicker]. [value] null shows [label] as a
/// dimmed placeholder; pass [onClear] to also show a "×" that clears it
/// back to null (for optional dates like Employees' DOB/joining date)
/// instead of the plain chevron.
class BrixenDateField extends StatelessWidget {
  final String? label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onClear;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const BrixenDateField({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.onClear,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2000),
          lastDate: lastDate ?? DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value != null
                    ? DateFormat('dd MMM yyyy').format(value!)
                    : (label ?? ''),
                style: TextStyle(
                  fontSize: 15,
                  color: value != null ? cs.onSurface : cs.onSurfaceVariant,
                ),
              ),
            ),
            if (onClear != null && value != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
