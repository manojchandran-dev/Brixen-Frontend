import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../products/presentation/providers/products_provider.dart';

double _num(Object? v) => double.tryParse('${v ?? ''}') ?? 0;
int _int(Object? v) => int.tryParse('${v ?? ''}') ?? _num(v).round();

/// One product's stock (`GET /inventory`).
class StockItem {
  final String productId;
  final String name;
  final String category;
  final int quantity;
  final int lowStockThreshold;

  /// 'in' | 'low' | 'out'.
  final String status;
  final double value;

  const StockItem({
    required this.productId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.lowStockThreshold,
    required this.status,
    required this.value,
  });

  factory StockItem.fromJson(Map<String, dynamic> j) {
    final qty = _int(j['stock_quantity']);
    final threshold = _int(j['low_stock_threshold'] ?? 5);
    final category = j['category'] is Map
        ? '${(j['category'] as Map)['name'] ?? ''}'
        : '${j['category_name'] ?? j['category'] ?? ''}';
    return StockItem(
      productId: '${j['id'] ?? j['product_id']}',
      name: '${j['product_name'] ?? j['name'] ?? ''}',
      category: category,
      quantity: qty,
      lowStockThreshold: threshold,
      status:
          '${j['stock_status'] ?? (qty <= 0
                      ? 'out'
                      : qty <= threshold
                      ? 'low'
                      : 'in')}'
              .toLowerCase(),
      value: _num(j['stock_value']),
    );
  }
}

class StockSummary {
  final int products, inStock, low, out, units;
  final double value;
  const StockSummary({
    required this.products,
    required this.inStock,
    required this.low,
    required this.out,
    required this.units,
    required this.value,
  });

  factory StockSummary.fromJson(Map<String, dynamic> j, List<StockItem> items) {
    // Server summary; anything missing is worked out from the items.
    int count(String s) => items.where((i) => i.status == s).length;
    return StockSummary(
      products: _int(j['products'] ?? j['total_products'] ?? items.length),
      inStock: _int(j['in_stock'] ?? j['in'] ?? count('in')),
      low: _int(j['low_stock'] ?? j['low'] ?? count('low')),
      out: _int(j['out_of_stock'] ?? j['out'] ?? count('out')),
      units: _int(
        j['total_units'] ??
            items.fold<int>(0, (a, i) => a + (i.quantity > 0 ? i.quantity : 0)),
      ),
      value: j['stock_value'] != null || j['total_value'] != null
          ? _num(j['stock_value'] ?? j['total_value'])
          : items.fold<double>(0, (a, i) => a + i.value),
    );
  }
}

class Inventory {
  final List<StockItem> items;
  final StockSummary summary;
  const Inventory(this.items, this.summary);
}

/// Every product's stock plus the summary — all pages (100 each).
final inventoryProvider = FutureProvider.autoDispose<Inventory>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final items = <StockItem>[];
    Map<String, dynamic> summary = const {};
    for (var page = 1; page <= 50; page++) {
      final resp = await dio.get(
        ApiEndpoints.inventory,
        queryParameters: {'page': page, 'limit': 100},
      );
      final body = resp.data is Map ? resp.data as Map : const {};
      final data = body['data'] ?? body;
      final rows = data is List
          ? data
          : (data['items'] ?? data['products'] ?? const []) as List;
      items.addAll([
        for (final r in rows)
          StockItem.fromJson(Map<String, dynamic>.from(r as Map)),
      ]);
      if (page == 1) {
        final s = (data is Map ? data['summary'] : null) ?? body['summary'];
        if (s is Map) summary = Map<String, dynamic>.from(s);
      }
      final meta = body['meta'] ?? (data is Map ? data['meta'] : null);
      final pages = meta is Map ? _int(meta['pages']) : 1;
      if (rows.length < 100 || page >= pages) break;
    }
    return Inventory(items, StockSummary.fromJson(summary, items));
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

/// One row of the stock ledger (`GET /inventory/movements`).
class StockMovement {
  final String productId;
  final String productName;

  /// 'purchase' | 'sale' | 'adjustment'.
  final String type;

  /// opening | correction | damage | return | other (adjustments).
  final String? reason;

  /// Signed: + in, − out.
  final int quantity;
  final int balanceAfter;
  final String? note;
  final String? by;
  final DateTime at;

  const StockMovement({
    required this.productId,
    required this.productName,
    required this.type,
    required this.reason,
    required this.quantity,
    required this.balanceAfter,
    required this.note,
    required this.by,
    required this.at,
  });

  factory StockMovement.fromJson(Map<String, dynamic> j) {
    final by =
        j['created_by_name'] ??
        (j['created_by'] is Map
            ? (j['created_by'] as Map)['name'] ??
                  (j['created_by'] as Map)['email']
            : j['user_name']);
    return StockMovement(
      productId: '${j['product_id'] ?? ''}',
      productName:
          '${j['product_name'] ?? (j['product'] is Map ? (j['product'] as Map)['product_name'] : '') ?? ''}',
      type: '${j['type'] ?? ''}'.toLowerCase(),
      reason: j['reason']?.toString(),
      quantity: _int(j['quantity']),
      balanceAfter: _int(j['balance_after']),
      note: j['note']?.toString(),
      by: by?.toString(),
      at:
          DateTime.tryParse('${j['created_at'] ?? ''}')?.toLocal() ??
          DateTime.now(),
    );
  }
}

/// Query for [stockMovementsProvider] — a stable string (the family key).
/// [type]: purchase | sale | adjustment; dates are inclusive days.
String movementsQuery({
  String? productId,
  String? type,
  DateTime? from,
  DateTime? to,
}) {
  String day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  return Uri(
    queryParameters: {
      if (from != null) 'from': day(from),
      if (productId != null && productId.isNotEmpty) 'product_id': productId,
      if (to != null) 'to': day(to),
      'type': ?type,
    },
  ).query;
}

/// The ledger, newest first, for a [movementsQuery] ('' = everything).
/// ponytail: latest 100 only; page on scroll if history gets long.
final stockMovementsProvider = FutureProvider.autoDispose
    .family<List<StockMovement>, String>((ref, query) async {
      try {
        final resp = await ref
            .read(dioProvider)
            .get(
              ApiEndpoints.inventoryMovements,
              queryParameters: {'limit': 100, ...Uri.splitQueryString(query)},
            );
        final data = resp.data['data'] ?? resp.data;
        final rows = data is List ? data : (data['items'] ?? const []) as List;
        return [
          for (final r in rows)
            StockMovement.fromJson(Map<String, dynamic>.from(r as Map)),
        ];
      } on DioException catch (e) {
        throw mapDioError(e);
      }
    });

/// Adjustment reasons the API accepts.
const stockReasons = ['opening', 'correction', 'damage', 'return', 'other'];

/// \`POST /inventory/adjustments\`: either a change ([change], e.g. −2) or a
/// stock count ([setTo]). Refreshes stock everywhere afterwards.
Future<void> adjustStock(
  WidgetRef ref, {
  required String productId,
  int? change,
  int? setTo,
  required String reason,
  String? note,
}) async {
  assert((change == null) != (setTo == null));
  try {
    await ref
        .read(dioProvider)
        .post(
          ApiEndpoints.inventoryAdjustments,
          data: {
            'product_id': int.tryParse(productId) ?? productId,
            'quantity': ?change,
            'set_to': ?setTo,
            'reason': reason,
            if (note != null && note.isNotEmpty) 'note': note,
          },
        );
  } on DioException catch (e) {
    throw mapDioError(e);
  }
  ref.invalidate(inventoryProvider);
  ref.invalidate(stockMovementsProvider);
  ref.invalidate(productsProvider);
}
