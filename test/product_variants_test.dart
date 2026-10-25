import 'package:brixen/features/products/data/models/product_model.dart';
import 'package:brixen/features/products/domain/entities/product.dart';
import 'package:brixen/features/products/presentation/widgets/variant_builder.dart';
import 'package:brixen/features/sales/domain/entities/sale_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'a product with variants parses each size and falls back to its prices',
    () {
      final p = ProductModel.fromJson({
        'id': 'PROD1',
        'product_name': 'Polo',
        'gender': 'Men',
        'cost_price': '200',
        'retail_price': '450',
        'wholesale_price': '380',
        'stock_quantity': 12,
        'product_variants': [
          {'id': 'PVAR1', 'size': 'M', 'color': 'Blue', 'stock_quantity': 5},
          {
            'id': 'PVAR2',
            'size': 'XL',
            'retail_price': '520',
            'sku': 'POLO-XL',
            'stock_quantity': 7,
          },
        ],
      });
      expect(p.hasVariants, isTrue);
      expect([for (final v in p.variants) v.label], ['M / Blue', 'XL']);
      expect(p.retailFor(p.variants[0]), 450, reason: 'no own price → product');
      expect(p.retailFor(p.variants[1]), 520);
      expect(p.wholesaleFor(p.variants[1]), 380);
      expect(p.variants[1].sku, 'POLO-XL');
    },
  );

  test(
    'variants body: saved rows keep their id, new rows send opening stock',
    () {
      final body = ProductModel.toVariantsBody(const [
        ProductVariant(
          id: 'PVAR1',
          size: 'M',
          retailPrice: 450,
          openingStock: 9,
        ),
        ProductVariant(size: 'L', openingStock: 4),
      ]);
      final rows = body['variants'] as List;
      expect(rows[0]['id'], 'PVAR1');
      expect(rows[0].containsKey('opening_stock'), isFalse);
      expect(rows[1].containsKey('id'), isFalse);
      expect(rows[1]['opening_stock'], 4);
    },
  );

  test('sizes × colours make every combination, keeping typed prices', () {
    final d = VariantDrafts()
      ..sizes.addAll(['S', 'M'])
      ..colours.addAll(['Blue', 'Black']);
    expect(
      [for (final r in d.rows) r.label],
      ['S / Blue', 'S / Black', 'M / Blue', 'M / Black'],
    );
    d.rows[2].retail.text = '499';
    d.colours.remove('Black');
    expect([for (final r in d.rows) r.label], ['S / Blue', 'M / Blue']);
    expect(d.rows[1].toVariant().retailPrice, 499);
    d.dispose();
  });

  test('sizes only, and a saved product loads back into the form', () {
    final d = VariantDrafts()
      ..load(const [
        ProductVariant(id: 'V1', size: '30', stockQuantity: 3),
        ProductVariant(id: 'V2', size: '32', wholesalePrice: 300),
      ]);
    expect(d.sizes, ['30', '32']);
    expect(d.colours, isEmpty);
    final rows = d.rows;
    expect([for (final r in rows) r.id], ['V1', 'V2']);
    expect(rows[1].wholesale.text, '300');
    expect(rows[0].savedStock, 3);
    d.dispose();
  });

  test('a sale line carries its size', () {
    const item = SaleItem(
      productId: 'PROD1',
      productName: 'Polo',
      variantId: 'PVAR1',
      variantLabel: 'M / Blue',
      priceType: 'retail',
      price: 450,
      quantity: 2,
    );
    expect(item.displayName, 'Polo (M / Blue)');
    expect(item.toBody()['variant_id'], 'PVAR1');
    final plain = SaleItem.fromJson({
      'product_id': 'P2',
      'product_name': 'Saree',
      'price': '900',
      'quantity': 1,
    });
    expect(plain.displayName, 'Saree');
    expect(plain.toBody().containsKey('variant_id'), isFalse);
  });
}
