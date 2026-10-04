import 'package:brixen/features/navigation/presentation/providers/nav_modules_provider.dart';
import 'package:brixen/features/permissions/presentation/providers/module_access_provider.dart';
import 'package:brixen/features/sales/domain/entities/sale.dart';
import 'package:brixen/features/sales/presentation/pages/sales_page.dart';
import 'package:brixen/features/sales/presentation/providers/sales_provider.dart';
import 'package:brixen/shared/providers/list_filter_options_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Sale _sale(String id, String? customer, double total, String status, {double? paid, String? type}) => Sale(
  id: id,
  customerName: customer,
  billDate: DateTime(2026, 9, 22),
  invoiceType: 'Tax Invoice',
  subtotal: total,
  taxAmount: 0,
  totalAmount: total,
  paymentType: type,
  paymentStatus: status,
  amountPaid: paid,
  createdAt: DateTime(2026, 9, 22),
);

final _sales = [
  _sale('s1', 'Karthik Raja with a rather long business name', 3776.85, 'Paid', paid: 3776.85, type: 'Cash'),
  _sale('s2', 'Fathima Beevi', 9450, 'Partial', paid: 5000, type: 'Bank Transfer'),
  _sale('s3', null, 249, 'Pending'),
];

class _Sales extends SalesNotifier {
  @override
  Future<List<Sale>> build() async => _sales;
}

void main() {
  testWidgets('Sale cards: compact, total pill, balance for partial', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          salesProvider.overrideWith(_Sales.new),
          navModulesProvider.overrideWith((ref) async => const []),
          listFilterOptionsProvider.overrideWith((ref, _) async => const {}),
          moduleAccessProvider.overrideWith(
            (ref, _) => const ModuleAccess(view: true, create: true, edit: true, delete: true),
          ),
        ],
        child: const MaterialApp(home: SalesPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('₹3,776.85'), findsOneWidget);
    expect(find.text('₹9,450'), findsOneWidget); // whole rupees: no .00
    expect(find.text('₹4,450 due'), findsOneWidget); // partial balance
    expect(find.text('22 Sep 2026 · Bank Transfer'), findsOneWidget);
    expect(find.text('Subtotal'), findsNothing); // moved to the detail sheet
  });
}
