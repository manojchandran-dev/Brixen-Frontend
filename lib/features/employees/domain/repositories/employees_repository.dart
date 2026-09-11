import '../entities/employee.dart';

abstract class EmployeesRepository {
  Future<List<Employee>> getEmployees({int page = 1, int limit = 200, String? search});
  Future<Employee> getEmployeeById(String id);
  Future<Employee> createEmployee(Map<String, dynamic> body);
  Future<Employee> updateStep2(String id, Map<String, dynamic> body, {String? companyId});
  Future<Employee> updateStep3(String id, Map<String, dynamic> body, {String? companyId});
  Future<Employee> updateEmployee(String id, Map<String, dynamic> body, {String? companyId});
  Future<void> deleteEmployee(String id, {String? companyId});
}
