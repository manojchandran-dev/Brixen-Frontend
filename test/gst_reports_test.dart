import 'package:brixen/features/reports/presentation/company/company_reports_data.dart';
import 'package:brixen/features/reports/presentation/superadmin/superadmin_reports_data.dart';
import 'package:brixen/features/sales/domain/entities/sale.dart';
import 'package:flutter_test/flutter_test.dart';

Sale _sale(String type, DateTime d, double sub, double pct) => Sale(
  id: '$type$d$sub',
  billType: type,
  billDate: d,
  subtotal: sub,
  taxPercentage: pct,
  taxAmount: sub * pct / 100,
  totalAmount: sub * (1 + pct / 100),
  paymentStatus: 'Paid',
  createdAt: d,
);

void main() {
  final now = DateTime(2026, 10, 25);
  final sales = [
    _sale(BillType.gst, DateTime(2026, 10, 24), 1000, 5),
    _sale(BillType.gst, DateTime(2026, 10, 23), 2000, 12),
    _sale(BillType.gst, DateTime(2026, 10, 22), 400, 5),
    _sale(BillType.secondary, DateTime(2026, 10, 24), 700, 0),
  ];

  test('salesByBillType keeps GST and secondary apart on the same buckets', () {
    final rows = salesByBillType(
      sales,
      const ReportPeriod(ReportRange.week),
      now,
    );
    expect(rows, hasLength(7));
    expect(rows.fold<int>(0, (a, r) => a + r.gst), 1050 + 2240 + 420);
    expect(rows.fold<int>(0, (a, r) => a + r.secondary), 700);
  });

  test('gstByRate groups GST bills by rate, ignoring secondary bills', () {
    final rates = gstByRate(sales);
    expect([for (final r in rates) r.rate], [12, 5]);
    expect(rates.last.taxable, 1400);
    expect(rates.last.tax, 70);
    expect(rates.last.bills, 2);
  });

  test('profit & loss counts both bill types and takes GST out', () {
    final pl = ProfitLoss.of(sales, const [], const []);
    expect(pl.gstBillSales, 1050 + 2240 + 420);
    expect(pl.secondaryBillSales, 700);
    expect(pl.grossSales, pl.gstBillSales + pl.secondaryBillSales);
    expect(pl.tax, 50 + 240 + 20);
    expect(pl.netSales, 1000 + 2000 + 400 + 700);
  });

  test('a GST bill with a secondary bill is left out of sales', () {
    final withSecondary = _sale(
      BillType.gst,
      DateTime(2026, 10, 24),
      5000,
      5,
    ).copyWith(hasSecondaryBill: true);
    final pl = ProfitLoss.of([...sales, withSecondary], const [], const []);
    expect(pl.grossSales, ProfitLoss.of(sales, const [], const []).grossSales);
    // The flag means nothing on a secondary bill.
    expect(
      _sale(
        BillType.secondary,
        DateTime(2026, 10, 24),
        700,
        0,
      ).copyWith(hasSecondaryBill: true).countsInSales,
      isTrue,
    );
  });
}
