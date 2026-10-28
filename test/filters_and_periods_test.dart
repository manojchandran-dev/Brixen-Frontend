import 'package:brixen/features/attendance/domain/attendance.dart';
import 'package:brixen/features/payroll/domain/payroll.dart';
import 'package:brixen/shared/widgets/chip_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('salary periods: months and Monday-to-Sunday weeks', () {
    expect(monthLabel('2026-10'), 'October 2026');
    expect(monthLabel('2026-10-26'), '26 Oct – 1 Nov 2026');
    expect(weekStartOf(DateTime(2026, 10, 28)), DateTime(2026, 10, 26));
    expect(weekStartOf(DateTime(2026, 10, 26)), DateTime(2026, 10, 26));
    expect(weekStartOf(DateTime(2026, 11, 1)), DateTime(2026, 10, 26));
  });

  test('date filters become from / to', () {
    final now = DateTime(2026, 10, 28, 15);
    final presets = DateFilter.presets(now);
    expect([for (final p in presets) p.label], [
      'Today',
      'Last 7 days',
      'Last 30 days',
      'This month',
    ]);
    expect(presets[1].params, {'from': '2026-10-22', 'to': '2026-10-28'});
    expect(presets[3].params, {'from': '2026-10-01', 'to': '2026-10-28'});

    final custom = DateFilter.custom(
      DateTimeRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 20)),
    );
    expect(custom.label, '5 Sep 26 – 20 Sep 26');
    expect(
      filterQueryParams({'days': custom, 'status': 'Active', 'gone': null}),
      {'from': '2026-09-05', 'to': '2026-09-20', 'status': 'Active'},
    );
  });

  test('shift sizes go from ¼ to 3 in quarters', () {
    expect(kShiftUnits.length, 12);
    expect(kShiftUnits.first, 0.25);
    expect(kShiftUnits.last, 3);
    expect(shiftUnitLabel(1.25), '1¼');
    expect(shiftUnitLabel(2.5), '2½');
  });
}
