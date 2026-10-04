import 'package:brixen/features/navigation/presentation/providers/nav_modules_provider.dart';
import 'package:brixen/features/permissions/presentation/providers/module_access_provider.dart';
import 'package:brixen/features/products/domain/entities/product.dart';
import 'package:brixen/features/products/presentation/pages/products_page.dart';
import 'package:brixen/features/products/presentation/providers/products_provider.dart';
import 'package:brixen/shared/providers/list_filter_options_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _products = [
  Product(id: 'p1', productCode: 'P1', productName: 'Chettinad Cotton Saree with a very long name', category: 'Sarees', gender: 'Women', designPattern: 'Checked', color: 'Maroon', costPrice: 650, retailPrice: 1199, wholesalePrice: 900, createdAt: DateTime(2026, 9, 1)),
  Product(id: 'p2', productCode: 'P2', productName: 'Kids Printed T-Shirt', category: '', gender: 'Kids', costPrice: 110, retailPrice: 249, wholesalePrice: 180, status: 'Inactive', createdAt: DateTime(2026, 9, 2)),
];

class _Products extends ProductsNotifier {
  @override
  Future<List<Product>> build() async => _products;
}

void main() {
  testWidgets('Product cards: compact, no overflow at phone size', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productsProvider.overrideWith(_Products.new),
          navModulesProvider.overrideWith((ref) async => const []),
          listFilterOptionsProvider.overrideWith((ref, _) async => const {}),
          moduleAccessProvider.overrideWith(
            (ref, _) => const ModuleAccess(view: true, create: true, edit: true, delete: true),
          ),
        ],
        child: const MaterialApp(home: ProductsPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Kids Printed T-Shirt'), findsOneWidget);
    expect(find.text('₹1199'), findsOneWidget);
    expect(find.text('Wholesale ₹900'), findsOneWidget);
    expect(find.text('Sarees'), findsWidgets); // category chip
    // Gone from the list: the three price chips, unit and field labels.
    expect(find.text('Cost'), findsNothing);
    expect(find.text('Retail Price'), findsNothing);
    expect(find.text('Attributes'), findsNothing);
  });
}
