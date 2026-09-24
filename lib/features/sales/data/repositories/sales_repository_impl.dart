import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/repositories/sales_repository.dart';
import '../datasources/sales_remote_datasource.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepositoryImpl(ref.read(salesRemoteDatasourceProvider));
});

class SalesRepositoryImpl implements SalesRepository {
  final SalesRemoteDatasource _ds;
  const SalesRepositoryImpl(this._ds);

  @override
  Future<List<Sale>> getSales({
    int page = 1,
    int limit = 200,
    String? search,
    String? customerId,
    String? paymentStatus,
    DateTime? from,
    DateTime? to,
  }) => _ds.getSales(
    page: page,
    limit: limit,
    search: search,
    customerId: customerId,
    paymentStatus: paymentStatus,
    from: from,
    to: to,
  );

  @override
  Future<Sale> getSaleById(String id, {String? companyId}) =>
      _ds.getSaleById(id, companyId: companyId);

  @override
  Future<Sale> createSale(Map<String, dynamic> body) => _ds.createSale(body);

  @override
  Future<Sale> updateSale(String id, Map<String, dynamic> body) =>
      _ds.updateSale(id, body);

  @override
  Future<Sale> updateSaleItems(
    String id,
    Map<String, dynamic> body, {
    String? companyId,
  }) => _ds.updateSaleItems(id, body, companyId: companyId);

  @override
  Future<List<SaleItem>> getSaleItems(String id, {String? companyId}) =>
      _ds.getSaleItems(id, companyId: companyId);

  @override
  Future<void> deleteSale(String id, {String? companyId}) =>
      _ds.deleteSale(id, companyId: companyId);
}
