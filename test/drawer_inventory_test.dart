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
  testWidgets('Inventory sits right after Products in the side menu', (tester) async {
    await _pump(tester, const [
      NavModule(id: '1', name: 'Employees'),
      NavModule(id: '2', name: 'Products'),
      NavModule(id: '3', name: 'Sales'),
    ]);
    expect(find.text('Inventory'), findsOneWidget);
    final products = tester.getTopLeft(find.text('Products')).dy;
    final inventory = tester.getTopLeft(find.text('Inventory')).dy;
    final sales = tester.getTopLeft(find.text('Sales')).dy;
    expect(inventory > products && inventory < sales, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('No Products access → no Inventory', (tester) async {
    await _pump(tester, const [NavModule(id: '1', name: 'Employees')]);
    expect(find.text('Inventory'), findsNothing);
  });
}
