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

final _inrExact = NumberFormat('#,##,##0.00', 'en_IN');

/// ₹ amount in full: ₹1,23,456 · ₹1,23,456.50 (paise only when there are any).
String rupeesExact(double v) {
  final sign = v < 0 ? '−' : '';
  final a = v.abs();
  final s = a == a.roundToDouble() ? _inr.format(a) : _inrExact.format(a);
  return '$sign₹$s';
}

/// ₹ amount as short as possible, for chart labels: ₹950 · ₹6.2K · ₹62K ·
/// ₹1.2L · ₹3.4Cr.
String rupeesShort(double v) {
  final sign = v < 0 ? '−' : '';
  final a = v.abs();
  String one(double x) => x >= 10
      ? x.toStringAsFixed(0)
      : x.toStringAsFixed(1).replaceAll('.0', '');
  if (a >= 10000000) return '$sign₹${one(a / 10000000)}Cr';
  if (a >= 100000) return '$sign₹${one(a / 100000)}L';
  if (a >= 1000) return '$sign₹${one(a / 1000)}K';
  return '$sign₹${a.toStringAsFixed(0)}';
}
