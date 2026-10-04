import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/employee_model.dart';

final employeesRemoteDatasourceProvider = Provider<EmployeesRemoteDatasource>((
  ref,
) {
  return EmployeesRemoteDatasource(ref.read(dioProvider));
});

class EmployeesRemoteDatasource {
  final Dio _dio;
  const EmployeesRemoteDatasource(this._dio);

  Future<List<EmployeeModel>> getEmployees({
    Map<String, String> filters = const {},
    String? search,
  }) async {
    try {
      final rows = await fetchAllPages(_dio, ApiEndpoints.employees, {
        if (search != null && search.isNotEmpty) 'search': search,

        ...filters,
      });
      return rows.map(EmployeeModel.fromJson).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<EmployeeModel> getEmployeeById(String id) async {
    try {
      final resp = await _dio.get(ApiEndpoints.employeeById(id));
      final data = resp.data['data'] ?? resp.data;
      return EmployeeModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<EmployeeModel> createEmployee(Map<String, dynamic> body) async {
    try {
      final resp = await _dio.post(ApiEndpoints.employees, data: body);
      final data = resp.data['data'] ?? resp.data;
      return EmployeeModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<EmployeeModel> updateStep2(
    String id,
    Map<String, dynamic> body, {
    String? companyId,
  }) async {
    try {
      final resp = await _dio.put(
        ApiEndpoints.employeeStep2(id),
        data: body,
        queryParameters: _companyIdParam(companyId),
      );
      final data = resp.data['data'] ?? resp.data;
      return EmployeeModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<EmployeeModel> updateStep3(
    String id,
    Map<String, dynamic> body, {
    String? companyId,
  }) async {
    try {
      final resp = await _dio.put(
        ApiEndpoints.employeeStep3(id),
        data: body,
        queryParameters: _companyIdParam(companyId),
      );
      final data = resp.data['data'] ?? resp.data;
      return EmployeeModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<EmployeeModel> updateEmployee(
    String id,
    Map<String, dynamic> body, {
    String? companyId,
  }) async {
    try {
      final resp = await _dio.put(
        ApiEndpoints.employeeById(id),
        data: body,
        queryParameters: _companyIdParam(companyId),
      );
      final data = resp.data['data'] ?? resp.data;
      return EmployeeModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> deleteEmployee(String id, {String? companyId}) async {
    try {
      await _dio.delete(
        ApiEndpoints.employeeById(id),
        queryParameters: _companyIdParam(companyId),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Map<String, dynamic>? _companyIdParam(String? companyId) =>
      companyId != null ? {'company_id': companyId} : null;
}
