import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customers_repository.dart';
import '../datasources/customers_remote_datasource.dart';

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepositoryImpl(ref.read(customersRemoteDatasourceProvider));
});

class CustomersRepositoryImpl implements CustomersRepository {
  final CustomersRemoteDatasource _ds;
  const CustomersRepositoryImpl(this._ds);

  @override
  Future<List<Customer>> getCustomers({int page = 1, int limit = 200, String? search}) =>
      _ds.getCustomers(page: page, limit: limit, search: search);

  @override
  Future<Customer> getCustomerById(String id) => _ds.getCustomerById(id);

  @override
  Future<Customer> createCustomer(Map<String, dynamic> body) => _ds.createCustomer(body);

  @override
  Future<Customer> updateCustomer(String id, Map<String, dynamic> body) =>
      _ds.updateCustomer(id, body);

  @override
  Future<void> deleteCustomer(String id, {String? companyId}) =>
      _ds.deleteCustomer(id, companyId: companyId);
}
