import 'package:flutter/material.dart';

/// One "label — value" line of a form's Review card. A short value sits
/// right-aligned beside its label; a long or multi-line one (a list of
/// items, a set of sizes) goes on its own full-width line below the label,
/// so it wraps instead of running off the screen.
class ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const ReviewRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  static const _stackAfter = 26;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(fontSize: 13, color: cs.onSurfaceVariant);
    final valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.45,
      color: valueColor ?? cs.onSurface,
    );
    if (value.length > _stackAfter || value.contains('\n')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 6),
          Text(value, style: valueStyle),
        ],
      );
    }
    return Row(
      children: [
        Text(label, style: labelStyle),
        const SizedBox(width: 16),
        Expanded(
          child: Text(value, textAlign: TextAlign.right, style: valueStyle),
        ),
      ],
    );
  }
}
