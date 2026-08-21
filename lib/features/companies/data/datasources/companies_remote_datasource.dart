import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/company_model.dart';

final companiesRemoteDatasourceProvider = Provider<CompaniesRemoteDatasource>((ref) {
  return CompaniesRemoteDatasource(ref.read(dioProvider));
});

class CompaniesRemoteDatasource {
  final Dio _dio;
  const CompaniesRemoteDatasource(this._dio);

  Future<List<CompanyModel>> getCompanies({
    int page = 1,
    int limit = 50,
    String? search,
  }) async {
    try {
      final resp = await _dio.get(ApiEndpoints.companies, queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      final data = resp.data['data'] ?? resp.data;
      final list = (data is List) ? data : (data['companies'] ?? data['items'] ?? []);
      return (list as List)
          .map((e) => CompanyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<CompanyModel> getCompanyById(String id) async {
    try {
      final resp = await _dio.get(ApiEndpoints.companyById(id));
      final data = resp.data['data'] ?? resp.data;
      return CompanyModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  // Step 1 — identity fields only; server auto-generates company_code
  Future<CompanyModel> createCompany(Map<String, dynamic> body) async {
    try {
      final resp = await _dio.post(ApiEndpoints.companies, data: body);
      final data = resp.data['data'] ?? resp.data;
      return CompanyModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  // Step 2 — contact & owner
  Future<CompanyModel> updateCompanyStep2(
      String id, Map<String, dynamic> body) async {
    try {
      final resp = await _dio.put(ApiEndpoints.companyStep2(id), data: body);
      final data = resp.data['data'] ?? resp.data;
      return CompanyModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  // Step 3 — location
  Future<CompanyModel> updateCompanyStep3(
      String id, Map<String, dynamic> body) async {
    try {
      final resp = await _dio.put(ApiEndpoints.companyStep3(id), data: body);
      final data = resp.data['data'] ?? resp.data;
      return CompanyModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<CompanyModel> updateCompanyStatus(String id, String status) async {
    try {
      final resp = await _dio.put(
        ApiEndpoints.companyStatus(id),
        data: {'status': status},
      );
      final data = resp.data['data'] ?? resp.data;
      return CompanyModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<CompanyModel> updateCompany(String id, Map<String, dynamic> body) async {
    try {
      final resp = await _dio.put(ApiEndpoints.companyById(id), data: body);
      final data = resp.data['data'] ?? resp.data;
      return CompanyModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> deleteCompany(String id) async {
    try {
      await _dio.delete(ApiEndpoints.companyById(id));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
