import '../entities/customer.dart';

abstract class CustomersRepository {
  Future<List<Customer>> getCustomers({int page = 1, int limit = 200, String? search});
  Future<Customer> getCustomerById(String id);
  Future<Customer> createCustomer(Map<String, dynamic> body);
  Future<Customer> updateCustomer(String id, Map<String, dynamic> body);
  Future<void> deleteCustomer(String id, {String? companyId});
}
