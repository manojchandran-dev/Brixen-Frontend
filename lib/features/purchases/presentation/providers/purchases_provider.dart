import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../data/purchase_model.dart';
import '../../domain/entities/purchase.dart';

final purchasesProvider =
    AsyncNotifierProvider<PurchasesNotifier, List<Purchase>>(
      PurchasesNotifier.new,
    );

/// Purchases from `/purchases`. Every change moves stock on the server, so
/// products and inventory are refreshed after it.
class PurchasesNotifier extends AsyncNotifier<List<Purchase>> {
  Dio get _dio => ref.read(dioProvider);

  @override
  Future<List<Purchase>> build() async {
    try {
      final rows = await fetchAllPages(_dio, ApiEndpoints.purchases, const {});
      return rows.map(purchaseFromJson).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// One purchase with its lines (the list may not include them).
  Future<Purchase> fetch(String id) async {
    try {
      final resp = await _dio.get(ApiEndpoints.purchaseById(id));
      return purchaseFromJson(
        Map<String, dynamic>.from(resp.data['data'] ?? resp.data),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Purchase> add(Purchase p, {required String companyId}) => _save(
    () => _dio.post(
      ApiEndpoints.purchases,
      data: purchaseToBody(p, companyId: companyId),
    ),
  );

  Future<Purchase> edit(Purchase p) => _save(
    () => _dio.put(ApiEndpoints.purchaseById(p.id), data: purchaseToBody(p)),
  );

  Future<void> delete(String id) async {
    try {
      await _dio.delete(ApiEndpoints.purchaseById(id));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
    state = AsyncData([
      for (final p in state.valueOrNull ?? const <Purchase>[])
        if (p.id != id) p,
    ]);
    _stockChanged();
  }

  Future<Purchase> _save(Future<Response> Function() request) async {
    final Purchase saved;
    try {
      final resp = await request();
      saved = purchaseFromJson(
        Map<String, dynamic>.from(resp.data['data'] ?? resp.data),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
    final list = state.valueOrNull ?? const <Purchase>[];
    state = AsyncData([
      saved,
      for (final p in list)
        if (p.id != saved.id) p,
    ]);
    _stockChanged();
    return saved;
  }

  void _stockChanged() {
    ref.invalidate(productsProvider);
    ref.invalidate(inventoryProvider);
  }
}
