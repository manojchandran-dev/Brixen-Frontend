import 'package:brixen/features/customers/domain/entities/customer.dart';
import 'package:brixen/features/customers/presentation/pages/customers_page.dart';
import 'package:brixen/features/customers/presentation/providers/customers_provider.dart';
import 'package:brixen/features/navigation/presentation/providers/nav_modules_provider.dart';
import 'package:brixen/features/permissions/presentation/providers/module_access_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _customers = [
  Customer(
    id: 'c1',
    name: 'Ramesh Babu with a long trading name',
    shopName: 'Ramesh Textiles',
    phone: '9840012345',
    gstNumber: '33ABCPR1111A1Z1',
    createdAt: DateTime(2026, 9, 1),
  ),
  Customer(id: 'c2', name: 'manoj', createdAt: DateTime(2026, 9, 2)),
];

class _Customers extends CustomersNotifier {
  @override
  Future<List<Customer>> build() async => _customers;
}

void main() {
  testWidgets('Customer cards: one card each, chips, tappable phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customersProvider.overrideWith(_Customers.new),
          navModulesProvider.overrideWith((ref) async => const []),
          moduleAccessProvider.overrideWith(
            (ref, _) => const ModuleAccess(
              view: true,
              create: true,
              edit: true,
              delete: true,
            ),
          ),
        ],
        child: const MaterialApp(home: CustomersPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Ramesh Textiles'), findsOneWidget);
    expect(find.text('9840012345'), findsOneWidget);
    expect(find.text('33ABCPR1111A1Z1'), findsOneWidget);
    expect(find.text('No GST'), findsOneWidget);
    expect(find.text('No shop name'), findsOneWidget);
    // The phone chip is the call action; no order amounts on the cards.
    expect(find.byIcon(Icons.call_rounded), findsOneWidget);
    expect(find.textContaining('₹'), findsNothing);
  });
}
