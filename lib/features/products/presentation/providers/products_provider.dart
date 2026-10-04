import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/super_admin_company_filter_provider.dart';
import '../../../masters/presentation/cubit/master_cubit.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/products_repository_impl.dart';
import '../../domain/entities/product.dart';

final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(
  ProductsNotifier.new,
);

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  List<Product> _all = [];

  @override
  Future<List<Product>> build() async {
    ref.watch(superAdminCompanyFilterProvider);
    // Category/unit names (cached after the first load).
    await Future.wait([
      masterCubit.ensureLoaded('productCategory'),
      masterCubit.ensureLoaded('unit'),
    ]);
    final list = await ref.read(productsRepositoryProvider).getProducts();
    _all = _resolveNames(list);
    return _all;
  }

  List<Product> _resolveNames(List<Product> list) {
    final categories = {
      for (final c in masterCubit.allItemsOfType('productCategory'))
        c.id: c.name,
    };
    final units = {
      for (final u in masterCubit.allItemsOfType('unit')) u.id: u.name,
    };
    return list
        .map(
          (p) => p.copyWith(
            category: p.categoryId != null
                ? (categories[p.categoryId] ?? p.category)
                : p.category,
            unit: p.unitId != null ? units[p.unitId] : null,
          ),
        )
        .toList();
  }

  Future<Product> updateProduct(Product product, {String? companyId}) async {
    final updated = await ref
        .read(productsRepositoryProvider)
        .updateProduct(
          product.id,
          ProductModel.toBody(product),
          companyId: companyId,
        );
    _replace(updated);
    return updated;
  }

  /// Sets stock and its low-stock level — PUT /products/:id with only
  /// those two fields (see [ProductModel.toStockBody]).
  Future<Product> updateStock(
    String id, {
    required int stockQuantity,
    required int lowStockThreshold,
    String? companyId,
  }) async {
    final updated = await ref
        .read(productsRepositoryProvider)
        .updateProduct(
          id,
          ProductModel.toStockBody(
            stockQuantity: stockQuantity,
            lowStockThreshold: lowStockThreshold,
          ),
          companyId: companyId,
        );
    _replace(updated);
    return updated;
  }

  // ── Registration wizard ─────────────────────────────────────────────────

  /// Step 1 (Basic) — POST, creates the product and returns it with the
  /// server-generated id/product_code.
  Future<Product> createStep1(
    Product product, {
    required String companyId,
  }) async {
    final created = await ref
        .read(productsRepositoryProvider)
        .createProduct(ProductModel.toStep1Body(product, companyId: companyId));
    _all = _resolveNames([..._all, created]);
    state = AsyncData(List.from(_all));
    return created;
  }

  /// Step 2 (Attributes) — PUT /:id/step2.
  Future<Product> updateStep2(
    String id,
    Product product, {
    String? companyId,
  }) async {
    final updated = await ref
        .read(productsRepositoryProvider)
        .updateStep2(
          id,
          ProductModel.toStep2Body(product),
          companyId: companyId,
        );
    _replace(updated);
    return updated;
  }

  /// Step 3 (Pricing) — PUT /:id/step3.
  Future<Product> updateStep3(
    String id,
    Product product, {
    String? companyId,
  }) async {
    final updated = await ref
        .read(productsRepositoryProvider)
        .updateStep3(
          id,
          ProductModel.toStep3Body(product),
          companyId: companyId,
        );
    _replace(updated);
    return updated;
  }

  /// Step 4 (Gallery & Status) — PUT /:id/step4.
  Future<Product> updateStep4(
    String id,
    Product product, {
    String? companyId,
  }) async {
    final updated = await ref
        .read(productsRepositoryProvider)
        .updateStep4(
          id,
          ProductModel.toStep4Body(product),
          companyId: companyId,
        );
    _replace(updated);
    return updated;
  }

  Future<void> deleteProduct(String id, {String? companyId}) async {
    await ref
        .read(productsRepositoryProvider)
        .deleteProduct(id, companyId: companyId);
    _all = _all.where((p) => p.id != id).toList();
    state = AsyncData(List.from(_all));
  }

  void _replace(Product updated) {
    _all = _resolveNames(
      _all.map((p) => p.id == updated.id ? updated : p).toList(),
    );
    state = AsyncData(List.from(_all));
  }
}

/// The products page's search/filter results: the server decides what
/// matches (`search` + filter params in [query], a query string), and the
/// items come from [productsProvider] so display names stay resolved. Rebuilds
/// whenever that list changes (add/edit/delete).
final productResultsProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, query) async {
      final all = await ref.watch(productsProvider.future);
      final rows = await ref
          .read(productsRepositoryProvider)
          .getProducts(filters: Uri.splitQueryString(query));
      final ids = {for (final r in rows) r.id};
      return [
        for (final x in all)
          if (ids.contains(x.id)) x,
      ];
    });
