import 'package:brixen/features/expenses/domain/entities/expense.dart';
import 'package:brixen/features/expenses/presentation/pages/expenses_page.dart';
import 'package:brixen/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:brixen/features/navigation/presentation/providers/nav_modules_provider.dart';
import 'package:brixen/features/permissions/presentation/providers/module_access_provider.dart';
import 'package:brixen/shared/providers/list_filter_options_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _expenses = [
  Expense(id: 'e1', categoryId: 'k1', category: 'Packaging', title: 'Poly covers and cartons for the Diwali season orders', amount: 1750, expenseDate: DateTime(2026, 9, 17), paymentMethod: 'UPI', receiptImagePath: 'https://x/r.png', createdAt: DateTime(2026, 9, 17)),
  Expense(id: 'e2', categoryId: 'k2', category: '', title: 'Auto', amount: 222.5, expenseDate: DateTime(2026, 9, 23), createdAt: DateTime(2026, 9, 23)),
];

class _Expenses extends ExpensesNotifier {
  @override
  Future<List<Expense>> build() async => _expenses;
}

void main() {
  testWidgets('Expense cards: compact, amount pill, no overflow', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expensesProvider.overrideWith(_Expenses.new),
          navModulesProvider.overrideWith((ref) async => const []),
          listFilterOptionsProvider.overrideWith((ref, _) async => const {}),
          moduleAccessProvider.overrideWith(
            (ref, _) => const ModuleAccess(view: true, create: true, edit: true, delete: true),
          ),
        ],
        child: const MaterialApp(home: ExpensesPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('₹1,750'), findsOneWidget); // whole rupees: no .00
    expect(find.text('₹222.50'), findsOneWidget);
    expect(find.text('17 Sep 2026 · UPI'), findsOneWidget);
    expect(find.text('Packaging'), findsWidgets);
    expect(find.byIcon(Icons.photo_rounded), findsOneWidget); // receipt badge
  });
}
