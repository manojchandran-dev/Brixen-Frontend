import 'package:brixen/features/navigation/domain/entities/nav_module.dart';
import 'package:brixen/features/navigation/presentation/providers/nav_modules_provider.dart';
import 'package:brixen/shared/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, List<NavModule> modules) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [navModulesProvider.overrideWith((ref) async => modules)],
      child: const MaterialApp(home: Scaffold(body: AppDrawer())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('grouped screens share one menu entry', (tester) async {
    await _pump(tester, const [
      NavModule(id: '1', name: 'Employees'),
      NavModule(id: '2', name: 'Products'),
      NavModule(id: '3', name: 'Expenses'),
      NavModule(id: '4', name: 'Purchases'),
      NavModule(id: '5', name: 'Sales'),
    ]);
    expect(find.text('Products & Inventory'), findsOneWidget);
    expect(find.text('Expenses & Purchases'), findsOneWidget);
    expect(find.text('Employees'), findsOneWidget);
    expect(find.text('Staff, permissions & salary'), findsOneWidget);
    for (final gone in [
      'Inventory',
      'Purchases',
      'Staff Permissions',
      'Salary Generation',
    ]) {
      expect(find.text(gone), findsNothing);
    }
    expect(find.text('Sales'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('purchases alone keeps its own entry', (tester) async {
    await _pump(tester, const [NavModule(id: '4', name: 'Purchases')]);
    expect(find.text('Purchases'), findsOneWidget);
    expect(find.text('Expenses & Purchases'), findsNothing);
  });
}
