import 'package:brixen/features/products/domain/entities/product.dart';
import 'package:brixen/features/products/data/models/product_model.dart';
import 'package:brixen/features/reports/presentation/company/company_reports_data.dart';
import 'package:brixen/features/sales/data/models/sale_model.dart';
import 'package:brixen/features/sales/domain/entities/sale.dart';
import 'package:brixen/features/sales/domain/entities/sale_item.dart';
import 'package:flutter_test/flutter_test.dart';

Sale _sale(String status, double total, {double? paid, List<SaleItem> items = const []}) => Sale(
  id: 's',
  billDate: DateTime(2026, 9, 27),
  subtotal: total,
  taxAmount: 0,
  totalAmount: total,
  paymentStatus: status,
  amountPaid: paid,
  items: items,
  createdAt: DateTime(2026, 9, 27),
);

Product _product(int stock, {int threshold = 5, double cost = 150}) => Product(
  id: 'p1',
  productCode: 'P1',
  productName: 'Shirt',
  category: 'Shirts',
  gender: 'Men',
  costPrice: cost,
  retailPrice: 500,
  wholesalePrice: 400,
  stockQuantity: stock,
  lowStockThreshold: threshold,
  createdAt: DateTime(2026),
);

void main() {
  test('Sale.balance: amount_paid when present, status fallback for old data', () {
    expect(_sale('Partial', 1000, paid: 400).balance, 600);
    expect(_sale('Paid', 1000, paid: 1000).balance, 0);
    expect(_sale('Paid', 1000).balance, 0); // old data, no amount_paid
    expect(_sale('Pending', 1000).balance, 1000);
    expect(_sale('Partial', 1000, paid: 1200).balance, 0); // never negative
  });

  test('Product stock states', () {
    expect(_product(20).isLowStock, isFalse);
    expect(_product(5).isLowStock, isTrue); // at the threshold
    expect(_product(0).isOutOfStock, isTrue);
    expect(_product(-2).isOutOfStock, isTrue); // oversold
    expect(_product(-2).isLowStock, isFalse);
  });

  test('JSON: stock fields, cost_price on lines, amount_paid', () {
    final p = ProductModel.fromJson({
      'id': 1, 'product_name': 'Shirt', 'gender': 'Men', 'cost_price': '150',
      'retail_price': '500', 'wholesale_price': '400', 'stock_quantity': 12, 'low_stock_threshold': 3,
    });
    expect(p.stockQuantity, 12);
    expect(p.lowStockThreshold, 3);
    expect(ProductModel.toStockBody(stockQuantity: 25, lowStockThreshold: 5), {'stock_quantity': 25, 'low_stock_threshold': 5});
    final s = SaleModel.fromJson({
      'id': 9, 'total_amount': '600', 'payment_status': 'Partial', 'amount_paid': '200',
      'sale_items': [
        {'product_id': 'p1', 'product_name': 'Shirt', 'price': '300', 'quantity': 2, 'cost_price': '100'},
      ],
    });
    expect(s.amountPaid, 200);
    expect(s.balance, 400);
    expect(s.items.single.costPrice, 100);
    expect(SaleModel.toBody(s)['amount_paid'], 200);
  });

  test('P&L: the cost saved on the line wins over the current product cost', () {
    final line = SaleItem(productId: 'p1', productName: 'Shirt', priceType: 'retail', price: 300, quantity: 2, costPrice: 100);
    final old = SaleItem(productId: 'p1', productName: 'Shirt', priceType: 'retail', price: 300, quantity: 1);
    final pl = ProfitLoss.of([_sale('Paid', 900, items: [line, old])], const [], [_product(10, cost: 150)]);
    expect(pl.cogs, 2 * 100 + 1 * 150); // saved cost; old line falls back
    expect(salesByProduct([_sale('Paid', 900, items: [line, old])], [_product(10, cost: 150)]).single.cost, 350);
  });
}
