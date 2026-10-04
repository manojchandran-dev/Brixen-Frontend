import 'package:brixen/features/inventory/presentation/pages/inventory_page.dart';
import 'package:brixen/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:brixen/features/permissions/presentation/providers/module_access_provider.dart';
import 'package:brixen/features/products/domain/entities/product.dart';
import 'package:brixen/features/products/presentation/providers/products_provider.dart';
import 'package:brixen/features/purchases/data/purchase_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _items = [
  StockItem.fromJson({
    'id': 1,
    'product_name': 'Cotton Shirt',
    'category_name': 'Shirts',
    'stock_quantity': 15,
    'low_stock_threshold': 5,
    'stock_status': 'in',
    'stock_value': 1350,
  }),
  StockItem.fromJson({
    'id': 2,
    'product_name': 'Kids Frock',
    'stock_quantity': 3,
    'low_stock_threshold': 5,
  }),
  StockItem.fromJson({'id': 3, 'product_name': 'Saree', 'stock_quantity': 0}),
];

final _moves = [
  StockMovement.fromJson({
    'product_id': 1,
    'product_name': 'Cotton Shirt',
    'type': 'purchase',
    'quantity': 5,
    'balance_after': 15,
    'created_by_name': 'Manoj',
    'created_at': '2026-09-27T10:00:00Z',
  }),
  StockMovement.fromJson({
    'product_id': 1,
    'product_name': 'Cotton Shirt',
    'type': 'adjustment',
    'reason': 'damage',
    'quantity': -2,
    'balance_after': 10,
    'note': 'Torn',
    'created_at': '2026-09-26T10:00:00Z',
  }),
];

void main() {
  test('Purchase JSON: lines, balance, body with items', () {
    final p = purchaseFromJson({
      'id': 7,
      'supplier_name': 'Sri Textiles',
      'bill_no': 'B-12',
      'bill_date': '2026-09-20',
      'subtotal': '500',
      'tax_percentage': '5',
      'tax_amount': '25',
      'total_amount': '525',
      'amount_paid': '200',
      'payment_status': 'Partial',
      'purchase_items': [
        {
          'product_id': 1,
          'product_name': 'Cotton Shirt',
          'quantity': 5,
          'unit_cost': '100',
        },
      ],
    });
    expect(p.items.single.lineTotal, 500);
    expect(p.balance, 325);
    final body = purchaseToBody(p, companyId: '2');
    expect(body['company_id'], 2);
    expect(body['bill_date'], '2026-09-20');
    expect(body['items'], [
      {'product_id': 1, 'quantity': 5, 'unit_cost': 100.0},
    ]);
  });

  test('Inventory parsing: status fallback, summary from items', () {
    expect(_items[1].status, 'low');
    expect(_items[2].status, 'out');
    expect(_items[0].category, 'Shirts');
    final s = StockSummary.fromJson(const {}, _items);
    expect((s.products, s.inStock, s.low, s.out, s.units), (3, 1, 1, 1, 18));
    expect(s.value, 1350);
    expect(_moves[1].quantity, -2);
    expect(_moves[0].by, 'Manoj');
  });

  testWidgets(
    'Inventory: overview, stock (SKU/size/colour), movements, transfers, reports',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryProvider.overrideWith(
              (ref) async =>
                  Inventory(_items, StockSummary.fromJson(const {}, _items)),
            ),
            productsProvider.overrideWith(_Products.new),
            stockMovementsProvider.overrideWith((ref, _) async => _moves),
            moduleAccessProvider.overrideWith(
              (ref, _) => const ModuleAccess(
                view: true,
                create: true,
                edit: true,
                delete: true,
              ),
            ),
          ],
          child: const MaterialApp(home: InventoryPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Overview: the four figures + actions.
      expect(find.text('18 units'), findsOneWidget);
      expect(find.text('Stock in'), findsOneWidget);

      // Stock: SKU / size / colour chips from the product.
      await tester.tap(find.text('Stock'));
      await tester.pumpAndSettle();
      expect(find.text('SHIRT-01'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
      await tester.tap(find.text('Low · 1'));
      await tester.pump();
      expect(find.text('Cotton Shirt'), findsNothing);
      await tester.tap(find.text('Kids Frock'));
      await tester.pumpAndSettle();
      expect(find.text('Save stock adjustment'), findsOneWidget);
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.text('Save stock adjustment'))).pop();
      await tester.pumpAndSettle();

      // Movements: in/out wording.
      await tester.tap(find.text('Movements'));
      await tester.pumpAndSettle();
      expect(find.text('Stock in · Purchase'), findsOneWidget);
      expect(find.text('Stock out · Damage'), findsOneWidget);

      await tester.tap(find.text('Transfers'));
      await tester.pumpAndSettle();
      expect(find.text('Stock transfers are coming'), findsOneWidget);

      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();
      expect(find.text('Stock summary'), findsOneWidget);
      await tester.drag(find.text('Stock summary'), const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(find.text('Stock valuation'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _Products extends ProductsNotifier {
  @override
  Future<List<Product>> build() async => [
    Product(
      id: '1',
      productCode: 'SHIRT-01',
      productName: 'Cotton Shirt',
      category: 'Shirts',
      gender: 'Men',
      size: 'M',
      color: 'Blue',
      costPrice: 90,
      retailPrice: 300,
      wholesalePrice: 250,
      createdAt: DateTime(2026),
    ),
  ];
}
