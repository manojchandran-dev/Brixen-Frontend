import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/super_admin_company_filter_provider.dart';
import '../../data/models/employee_model.dart';
import '../../data/repositories/employees_repository_impl.dart';
import '../../domain/entities/employee.dart';

final employeesProvider = AsyncNotifierProvider<EmployeesNotifier, List<Employee>>(
  EmployeesNotifier.new,
);

class EmployeesNotifier extends AsyncNotifier<List<Employee>> {
  List<Employee> _all = [];

  @override
  Future<List<Employee>> build() async {
    // superAdmin's "browse as company X" filter — refetch whenever it
    // changes, since CompanyScopeInterceptor reads it to scope this call.
    ref.watch(superAdminCompanyFilterProvider);
    final list = await ref.read(employeesRepositoryProvider).getEmployees();
    _all = _resolveManagerNames(list);
    return _all;
  }

  /// Fills in `managerName` locally for any employee whose manager the
  /// backend didn't already resolve, using the just-fetched list.
  List<Employee> _resolveManagerNames(List<Employee> list) {
    final byId = {for (final e in list) e.id: e};
    return list.map((e) {
      if (e.managerId != null && (e.managerName == null || e.managerName!.isEmpty)) {
        final manager = byId[e.managerId];
        if (manager != null) return e.copyWith(managerName: manager.fullName);
      }
      return e;
    }).toList();
  }

  Future<Employee> updateEmployee(Employee employee, {String? companyId}) async {
    final updated = await ref
        .read(employeesRepositoryProvider)
        .updateEmployee(employee.id, EmployeeModel.toBody(employee), companyId: companyId);
    _replace(updated);
    return updated;
  }

  // ── Registration wizard ─────────────────────────────────────────────────────

  /// Step 1 (Personal) — POST, creates the employee and returns it with the
  /// server-generated id/employee_code.
  Future<Employee> createStep1(Employee employee, {required String companyId}) async {
    final created = await ref
        .read(employeesRepositoryProvider)
        .createEmployee(EmployeeModel.toStep1Body(employee, companyId: companyId));
    _all = _resolveManagerNames([..._all, created]);
    state = AsyncData(List.from(_all));
    return created;
  }

  /// Step 2 (Employment) — PUT /:id/step2.
  Future<Employee> updateStep2(String id, Employee employee, {String? companyId}) async {
    final updated = await ref
        .read(employeesRepositoryProvider)
        .updateStep2(id, EmployeeModel.toStep2Body(employee), companyId: companyId);
    _replace(updated);
    return updated;
  }

  /// Step 3 (Banking) — PUT /:id/step3.
  Future<Employee> updateStep3(String id, Employee employee, {String? companyId}) async {
    final updated = await ref
        .read(employeesRepositoryProvider)
        .updateStep3(id, EmployeeModel.toStep3Body(employee), companyId: companyId);
    _replace(updated);
    return updated;
  }

  /// Step 4 (Review) — re-fetches from the server so the summary reflects
  /// exactly what was persisted, not just local form state.
  Future<Employee> fetchEmployeeDetail(String id) async {
    final fetched = await ref.read(employeesRepositoryProvider).getEmployeeById(id);
    _replace(fetched);
    return fetched;
  }

  Future<void> deleteEmployee(String id, {String? companyId}) async {
    await ref.read(employeesRepositoryProvider).deleteEmployee(id, companyId: companyId);
    _all = _all.where((e) => e.id != id).toList();
    state = AsyncData(List.from(_all));
  }

  void _replace(Employee updated) {
    _all = _resolveManagerNames(_all.map((e) => e.id == updated.id ? updated : e).toList());
    state = AsyncData(List.from(_all));
  }
}
