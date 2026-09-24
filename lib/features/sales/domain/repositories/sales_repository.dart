import '../entities/sale.dart';
import '../entities/sale_item.dart';

abstract class SalesRepository {
  Future<List<Sale>> getSales({
    int page = 1,
    int limit = 200,
    String? search,
    String? customerId,
    String? paymentStatus,
    DateTime? from,
    DateTime? to,
  });
  Future<Sale> getSaleById(String id, {String? companyId});
  Future<Sale> createSale(Map<String, dynamic> body);
  Future<Sale> updateSale(String id, Map<String, dynamic> body);
  Future<Sale> updateSaleItems(
    String id,
    Map<String, dynamic> body, {
    String? companyId,
  });
  Future<List<SaleItem>> getSaleItems(String id, {String? companyId});
  Future<void> deleteSale(String id, {String? companyId});
}
