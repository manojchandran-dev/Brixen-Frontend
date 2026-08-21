import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/customers_remote_datasource.dart';
import '../../data/models/customer_model.dart';
import '../../domain/entities/customer.dart';

final customersProvider = AsyncNotifierProvider<CustomersNotifier, List<Customer>>(
  CustomersNotifier.new,
);

class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  List<Customer> _all = [];

  @override
  Future<List<Customer>> build() async {
    _all = await ref.read(customersRemoteDatasourceProvider).getCustomers();
    return _all;
  }

  Future<Customer> addCustomer(Customer customer) async {
    final created = await ref
        .read(customersRemoteDatasourceProvider)
        .createCustomer(CustomerModel.toBody(customer));
    _all = [..._all, created];
    state = AsyncData(List.from(_all));
    return created;
  }

  Future<Customer> updateCustomer(Customer updated) async {
    final saved = await ref
        .read(customersRemoteDatasourceProvider)
        .updateCustomer(updated.id, CustomerModel.toBody(updated));
    _all = _all.map((c) => c.id == saved.id ? saved : c).toList();
    state = AsyncData(List.from(_all));
    return saved;
  }

  Future<void> deleteCustomer(String id) async {
    await ref.read(customersRemoteDatasourceProvider).deleteCustomer(id);
    _all = _all.where((c) => c.id != id).toList();
    state = AsyncData(List.from(_all));
  }
}
