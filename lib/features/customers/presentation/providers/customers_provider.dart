import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/super_admin_company_filter_provider.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customers_repository_impl.dart';
import '../../domain/entities/customer.dart';

final customersProvider = AsyncNotifierProvider<CustomersNotifier, List<Customer>>(
  CustomersNotifier.new,
);

class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  List<Customer> _all = [];

  @override
  Future<List<Customer>> build() async {
    ref.watch(superAdminCompanyFilterProvider);
    _all = await ref.read(customersRepositoryProvider).getCustomers();
    return _all;
  }

  Future<Customer> addCustomer(Customer customer, {required String companyId}) async {
    final created = await ref
        .read(customersRepositoryProvider)
        .createCustomer(CustomerModel.toBody(customer, companyId: companyId));
    _all = [..._all, created];
    state = AsyncData(List.from(_all));
    return created;
  }

  Future<Customer> updateCustomer(Customer updated, {String? companyId}) async {
    final saved = await ref
        .read(customersRepositoryProvider)
        .updateCustomer(updated.id, CustomerModel.toBody(updated, companyId: companyId));
    _all = _all.map((c) => c.id == saved.id ? saved : c).toList();
    state = AsyncData(List.from(_all));
    return saved;
  }

  Future<void> deleteCustomer(String id, {String? companyId}) async {
    await ref.read(customersRepositoryProvider).deleteCustomer(id, companyId: companyId);
    _all = _all.where((c) => c.id != id).toList();
    state = AsyncData(List.from(_all));
  }
}
