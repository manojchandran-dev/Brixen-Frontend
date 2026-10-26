import 'package:brixen/features/customers/domain/entities/customer.dart';
import 'package:brixen/features/products/domain/entities/product.dart';
import 'package:brixen/features/reports/presentation/company/company_reports_data.dart';
import 'package:brixen/features/sales/domain/entities/sale.dart';
import 'package:brixen/features/sales/domain/entities/sale_item.dart';
import 'package:flutter_test/flutter_test.dart';

final _day = DateTime(2026, 10, 20);

final _shirt = Product(
  id: 'p1',
  productCode: 'P1',
  productName: 'Shirt',
  category: 'Shirts',
  gender: 'Men',
  costPrice: 100,
  retailPrice: 500,
  wholesalePrice: 400,
  createdAt: _day,
  variants: const [
    ProductVariant(id: 'v1', size: 'M', color: 'Blue'),
    ProductVariant(id: 'v2', size: 'L', color: 'Blue'),
    ProductVariant(id: 'v3', color: 'Red'),
  ],
);

final _sock = Product(
  id: 'p2',
  productCode: 'P2',
  productName: 'Socks',
  category: '',
  gender: 'Men',
  costPrice: 10,
  retailPrice: 50,
  wholesalePrice: 40,
  createdAt: _day,
);

SaleItem _line(Product p, int qty, {String? variant, String? label}) =>
    SaleItem(
      productId: p.id,
      productName: p.productName,
      variantId: variant,
      variantLabel: label,
      priceType: 'retail',
      price: p.retailPrice,
      quantity: qty,
    );

Sale _sale(String? customer, List<SaleItem> items) => Sale(
  id: '${customer}_${items.length}',
  customerId: customer,
  billDate: _day,
  subtotal: items.fold(0, (a, i) => a + i.amount),
  taxAmount: 0,
  totalAmount: items.fold(0, (a, i) => a + i.amount),
  paymentStatus: 'Paid',
  items: items,
  createdAt: _day,
);

void main() {
  final sales = [
    _sale('c1', [
      _line(_shirt, 3, variant: 'v1'),
      _line(_shirt, 1, variant: 'v2'),
    ]),
    _sale('c2', [
      _line(_shirt, 2, variant: 'v1'),
      _line(_shirt, 1, variant: 'v3'),
      _line(_sock, 4),
    ]),
    // A size that's no longer on the product: taken from the saved label.
    _sale(null, [_line(_shirt, 2, variant: 'gone', label: 'XL / Blue')]),
  ];

  test('groups units by category, then size, most sold first', () {
    final cats = salesByCategorySize(sales, [_shirt, _sock]);
    expect(cats.map((c) => c.name), ['Shirts', 'Uncategorised']);

    final shirts = cats.first;
    expect(shirts.quantity, 9);
    expect(shirts.amount, 9 * 500);
    expect({for (final s in shirts.sizes) s.label: s.quantity}, {
      'M': 5,
      'L': 1,
      'No size': 1,
      'XL': 2,
    });
    expect(shirts.sizes.first.label, 'M');
    expect(cats.last.sizes.single.label, 'No size');
  });

  test('customer purchases carry units and the customer id', () {
    final rows = purchasesByCustomer(sales, [
      Customer(id: 'c1', name: 'Ravi', createdAt: _day),
      Customer(id: 'c2', name: 'Meena', createdAt: _day),
    ]);
    final ravi = rows.firstWhere((t) => t.label == 'Ravi');
    expect(ravi.key, 'c1');
    expect(ravi.quantity, 4);
    expect(rows.firstWhere((t) => t.label == 'Walk-in').key, '');

    // One customer's categories and sizes.
    final mine = salesByCategorySize(
      sales.where((s) => s.customerId == 'c2'),
      [_shirt, _sock],
    );
    // 4 socks beat 3 shirts.
    expect(mine.map((c) => c.name), ['Uncategorised', 'Shirts']);
    expect(mine.last.sizes.first.label, 'M');
  });
}
