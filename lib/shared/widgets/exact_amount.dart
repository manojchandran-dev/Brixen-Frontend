import 'package:flutter/material.dart';

import '../../core/utils/money.dart';

/// Tap [child] to see [amount] in full (₹1,23,456) for 10 seconds — for
/// figures shown compact (₹1.2L). Without an amount it's just [child].
class ExactAmount extends StatelessWidget {
  final double? amount;
  final Widget child;
  const ExactAmount({super.key, required this.amount, required this.child});

  @override
  Widget build(BuildContext context) {
    final a = amount;
    if (a == null) return child;
    return Tooltip(
      message: rupeesExact(a),
      triggerMode: TooltipTriggerMode.tap,
      enableFeedback: true,
      preferBelow: false,
      showDuration: const Duration(seconds: 10),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
      child: child,
    );
  }
}
