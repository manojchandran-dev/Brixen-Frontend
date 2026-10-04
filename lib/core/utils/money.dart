import 'package:intl/intl.dart';

final _inr = NumberFormat('#,##,##0', 'en_IN');

/// ₹ amount, compact above a lakh: ₹12,450 · ₹1.2L · ₹3.4Cr (− when negative).
String rupees(double v) {
  final sign = v < 0 ? '−' : '';
  final a = v.abs();
  if (a >= 10000000) return '$sign₹${(a / 10000000).toStringAsFixed(1)}Cr';
  if (a >= 100000) return '$sign₹${(a / 100000).toStringAsFixed(1)}L';
  return '$sign₹${_inr.format(a)}';
}
