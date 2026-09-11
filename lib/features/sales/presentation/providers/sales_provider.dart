import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/super_admin_company_filter_provider.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/presentation/providers/customers_provider.dart';
import '../../data/models/sale_model.dart';
import '../../data/repositories/sales_repository_impl.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';

final salesProvider = AsyncNotifierProvider<SalesNotifier, List<Sale>>(
  SalesNotifier.new,
);

class SalesNotifier extends AsyncNotifier<List<Sale>> {
  List<Sale> _all = [];

  @override
  Future<List<Sale>> build() async {
    ref.watch(superAdminCompanyFilterProvider);
    final customers = await ref.read(customersProvider.future);
    final list = await ref.read(salesRepositoryProvider).getSales();
    _all = _resolveNames(list, customers);
    return _all;
  }

  /// The API only returns `customer_id` — fills in the display name
  /// client-side from the already-loaded Customers data.
  List<Sale> _resolveNames(List<Sale> list, List<Customer> customers) {
    final names = {for (final c in customers) c.id: c.name};
    return list
        .map((s) => s.copyWith(customerName: names[s.customerId] ?? s.customerId))
        .toList();
  }

  Future<Sale> addSale(Sale sale, {required String companyId}) async {
    final created = await ref
        .read(salesRepositoryProvider)
        .createSale(SaleModel.toBody(sale, companyId: companyId));
    final customers = ref.read(customersProvider).value ?? [];
    _all = _resolveNames([..._all, created], customers);
    state = AsyncData(List.from(_all));
    return created;
  }

  Future<Sale> updateSale(Sale updated, {String? companyId}) async {
    final saved = await ref
        .read(salesRepositoryProvider)
        .updateSale(updated.id, SaleModel.toBody(updated, companyId: companyId));
    final customers = ref.read(customersProvider).value ?? [];
    _all = _resolveNames(_all.map((s) => s.id == saved.id ? saved : s).toList(), customers);
    state = AsyncData(List.from(_all));
    return saved;
  }

  /// `PUT /sales/:id/step2` — replaces the sale's line items and tax
  /// percentage; the server recomputes subtotal/tax_amount/total_amount and
  /// returns the updated sale.
  Future<Sale> updateSaleItems(
    String saleId,
    List<SaleItem> items,
    double taxPercentage, {
    String? companyId,
  }) async {
    final updated = await ref
        .read(salesRepositoryProvider)
        .updateSaleItems(saleId, SaleModel.toStep2Body(items, taxPercentage), companyId: companyId);
    _replace(updated);
    return updated;
  }

  Future<void> deleteSale(String id, {String? companyId}) async {
    await ref.read(salesRepositoryProvider).deleteSale(id, companyId: companyId);
    _all = _all.where((s) => s.id != id).toList();
    state = AsyncData(List.from(_all));
  }

  void _replace(Sale updated) {
    final customers = ref.read(customersProvider).value ?? [];
    final exists = _all.any((s) => s.id == updated.id);
    final list = exists
        ? _all.map((s) => s.id == updated.id ? updated : s).toList()
        : [..._all, updated];
    _all = _resolveNames(list, customers);
    state = AsyncData(List.from(_all));
  }
}
