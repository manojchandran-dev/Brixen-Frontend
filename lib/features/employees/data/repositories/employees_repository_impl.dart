import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/employees_repository.dart';
import '../datasources/employees_remote_datasource.dart';

final employeesRepositoryProvider = Provider<EmployeesRepository>((ref) {
  return EmployeesRepositoryImpl(ref.read(employeesRemoteDatasourceProvider));
});

class EmployeesRepositoryImpl implements EmployeesRepository {
  final EmployeesRemoteDatasource _ds;
  const EmployeesRepositoryImpl(this._ds);

  @override
  Future<List<Employee>> getEmployees({int page = 1, int limit = 200, String? search}) =>
      _ds.getEmployees(page: page, limit: limit, search: search);

  @override
  Future<Employee> getEmployeeById(String id) => _ds.getEmployeeById(id);

  @override
  Future<Employee> createEmployee(Map<String, dynamic> body) => _ds.createEmployee(body);

  @override
  Future<Employee> updateStep2(String id, Map<String, dynamic> body, {String? companyId}) =>
      _ds.updateStep2(id, body, companyId: companyId);

  @override
  Future<Employee> updateStep3(String id, Map<String, dynamic> body, {String? companyId}) =>
      _ds.updateStep3(id, body, companyId: companyId);

  @override
  Future<Employee> updateEmployee(String id, Map<String, dynamic> body, {String? companyId}) =>
      _ds.updateEmployee(id, body, companyId: companyId);

  @override
  Future<void> deleteEmployee(String id, {String? companyId}) =>
      _ds.deleteEmployee(id, companyId: companyId);
}
