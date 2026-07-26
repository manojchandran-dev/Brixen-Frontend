import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/employee.dart';

final employeesProvider = AsyncNotifierProvider<EmployeesNotifier, List<Employee>>(
  EmployeesNotifier.new,
);

class EmployeesNotifier extends AsyncNotifier<List<Employee>> {
  List<Employee> _all = [];

  @override
  Future<List<Employee>> build() async {
    _all = [];
    return _all;
  }

  String nextEmployeeCode() => 'EMP${(_all.length + 1).toString().padLeft(4, '0')}';

  Future<void> addEmployee(Employee employee) async {
    _all = [..._all, employee];
    state = AsyncData(List.from(_all));
  }

  Future<void> updateEmployee(Employee updated) async {
    _all = _all.map((e) => e.id == updated.id ? updated : e).toList();
    state = AsyncData(List.from(_all));
  }

  Future<void> deleteEmployee(String id) async {
    _all = _all.where((e) => e.id != id).toList();
    state = AsyncData(List.from(_all));
  }
}
