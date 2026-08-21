import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/presentation/providers/customers_provider.dart';
import '../../data/datasources/sales_remote_datasource.dart';
import '../../data/models/sale_model.dart';
import '../../domain/entities/sale.dart';

final salesProvider = AsyncNotifierProvider<SalesNotifier, List<Sale>>(
  SalesNotifier.new,
);

class SalesNotifier extends AsyncNotifier<List<Sale>> {
  List<Sale> _all = [];

  @override
  Future<List<Sale>> build() async {
    final customers = await ref.read(customersProvider.future);
    final list = await ref.read(salesRemoteDatasourceProvider).getSales();
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

  Future<Sale> addSale(Sale sale) async {
    final created = await ref
        .read(salesRemoteDatasourceProvider)
        .createSale(SaleModel.toBody(sale));
    final customers = ref.read(customersProvider).value ?? [];
    _all = _resolveNames([..._all, created], customers);
    state = AsyncData(List.from(_all));
    return created;
  }

  Future<Sale> updateSale(Sale updated) async {
    final saved = await ref
        .read(salesRemoteDatasourceProvider)
        .updateSale(updated.id, SaleModel.toBody(updated));
    final customers = ref.read(customersProvider).value ?? [];
    _all = _resolveNames(_all.map((s) => s.id == saved.id ? saved : s).toList(), customers);
    state = AsyncData(List.from(_all));
    return saved;
  }

  Future<void> deleteSale(String id) async {
    await ref.read(salesRemoteDatasourceProvider).deleteSale(id);
    _all = _all.where((s) => s.id != id).toList();
    state = AsyncData(List.from(_all));
  }
}
