import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/company_page.dart';
import '../models/company_model.dart';

final companiesRemoteDatasourceProvider = Provider<CompaniesRemoteDatasource>((
  ref,
) {
  return CompaniesRemoteDatasource(ref.read(dioProvider));
});

class CompaniesRemoteDatasource {
  final Dio _dio;
  const CompaniesRemoteDatasource(this._dio);

  Future<List<CompanyModel>> getCompanies({
    int page = 1,
    int limit = 50,
    String? search,
    bool deleted = false,
  }) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.companies,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (deleted) 'deleted': 'true',
        },
      );
      final data = resp.data['data'] ?? resp.data;
      final list = (data is List)
          ? data
          : (data['companies'] ?? data['items'] ?? []);
      return (list as List)
          .map((e) => CompanyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// The Companies page list: server-side search + status/plan/industry
  /// filters, with the total and the per-chip counts.
  Future<CompanyPage> getCompanyPage({
    String? search,
    String? status,
    String? plan,
    String? industry,
    int page = 1,
    int limit = 50,
    bool withAccess = false,
  }) async {
    try {
      final resp = await _dio.get(
        withAccess ? ApiEndpoints.permissionCompanies : ApiEndpoints.companies,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          'status': ?status,
          'subscription_plan': ?plan,
          'industry_type': ?industry,
        },
      );
      final data = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
      final items = ((data['items'] ?? data['companies'] ?? []) as List)
          .map((e) => CompanyModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final total =
          ((data['meta'] as Map?)?['total'] as num?)?.toInt() ?? items.length;
      final counts = <String, Map<String, int>>{
        for (final f in ((data['filters'] as Map?) ?? const {}).entries)
          f.key.toString(): {
            for (final c in (f.value as Map).entries)
              c.key.toString(): (c.value as num).toInt(),
          },
      };
      return CompanyPage(items: items, total: total, counts: counts);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<CompanyModel> getCompanyById(String id) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.companyById(id),
        queryParameters: {'company_id': id},
      );
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
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.put(
        ApiEndpoints.companyStep2(id),
        data: body,
        queryParameters: {'company_id': id},
      );
      final data = resp.data['data'] ?? resp.data;
      return CompanyModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  // Step 3 — location
  Future<CompanyModel> updateCompanyStep3(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.put(
        ApiEndpoints.companyStep3(id),
        data: body,
        queryParameters: {'company_id': id},
      );
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
        queryParameters: {'company_id': id},
      );
      final data = resp.data['data'] ?? resp.data;
      return CompanyModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<CompanyModel> updateCompany(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.put(
        ApiEndpoints.companyById(id),
        data: body,
        queryParameters: {'company_id': id},
      );
      final data = resp.data['data'] ?? resp.data;
      return CompanyModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<CompanyModel> restoreCompany(String id) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.companyRestore(id),
        queryParameters: {'company_id': id},
      );
      final data = resp.data['data'] ?? resp.data;
      return CompanyModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> deleteCompany(String id) async {
    try {
      await _dio.delete(
        ApiEndpoints.companyById(id),
        queryParameters: {'company_id': id},
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
