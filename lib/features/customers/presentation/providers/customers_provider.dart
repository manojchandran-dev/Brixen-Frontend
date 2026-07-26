import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer.dart';

final customersProvider = AsyncNotifierProvider<CustomersNotifier, List<Customer>>(
  CustomersNotifier.new,
);

class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  List<Customer> _all = [];

  @override
  Future<List<Customer>> build() async {
    // TODO: load from API
    _all = [];
    return _all;
  }

  Future<void> addCustomer(Customer customer) async {
    _all = [..._all, customer];
    state = AsyncData(List.from(_all));
  }

  Future<void> updateCustomer(Customer updated) async {
    _all = _all.map((c) => c.id == updated.id ? updated : c).toList();
    state = AsyncData(List.from(_all));
  }

  Future<void> deleteCustomer(String id) async {
    _all = _all.where((c) => c.id != id).toList();
    state = AsyncData(List.from(_all));
  }
}
