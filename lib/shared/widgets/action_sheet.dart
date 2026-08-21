import 'package:flutter/material.dart';

class ActionSheetItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool selected;
  const ActionSheetItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.selected = false,
  });
}

/// Shows a rounded bottom sheet of full-width, button-style actions —
/// used in place of the cramped 3-dot `PopupMenuButton` dropdown across
/// list cards (Employees, Customers, Expenses, ...).
Future<void> showActionSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<ActionSheetItem> items,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ActionSheet(title: title, subtitle: subtitle, items: items),
  );
}

class _ActionSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<ActionSheetItem> items;
  const _ActionSheet({required this.title, required this.subtitle, required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36, height: 4,
              decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      item.onTap();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: item.selected ? 0.16 : 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: item.color.withValues(alpha: item.selected ? 0.5 : 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(item.icon, size: 18, color: item.color),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(item.label, style: TextStyle(color: item.color, fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                          if (item.selected) Icon(Icons.check_rounded, size: 18, color: item.color),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
