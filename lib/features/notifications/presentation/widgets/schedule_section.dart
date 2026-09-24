import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Send Now / Schedule for Later — reused by both the Push Notification and
/// Announcement create forms. When scheduled, exposes a date and time
/// picker in the same visual language as `_DatePickerField` (Sales) — no
/// new date-range package needed, just the SDK's built-in
/// `showDatePicker`/`showTimePicker`. Always Asia/Kolkata — the only
/// timezone this app's companies operate in, so there's nothing to pick.
class ScheduleSection extends StatelessWidget {
  final bool isScheduled;
  final ValueChanged<bool> onModeChanged;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const ScheduleSection({
    super.key,
    required this.isScheduled,
    required this.onModeChanged,
    required this.date,
    required this.onDateChanged,
    required this.time,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _ModeChip(
                label: 'Send Now',
                selected: !isScheduled,
                onTap: () => onModeChanged(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ModeChip(
                label: 'Schedule for Later',
                selected: isScheduled,
                onTap: () => onModeChanged(true),
              ),
            ),
          ],
        ),
        if (isScheduled) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) onDateChanged(picked);
                  },
                  child: _PickerBox(
                    icon: Icons.calendar_today_outlined,
                    text: DateFormat('dd MMM yyyy').format(date),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: time,
                    );
                    if (picked != null) onTimeChanged(picked);
                  },
                  child: _PickerBox(
                    icon: Icons.access_time_rounded,
                    text: time.format(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.public_rounded,
                size: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Asia/Kolkata (IST)',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : Theme.of(context).dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _PickerBox extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PickerBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: cs.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
