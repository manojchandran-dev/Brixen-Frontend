import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/superadmin_dashboard.dart';
import '../models/dashboard_summary_model.dart';
import '../models/superadmin_dashboard_model.dart';

final dashboardRemoteDatasourceProvider = Provider<DashboardRemoteDatasource>((ref) {
  return DashboardRemoteDatasource(ref.read(dioProvider));
});

class DashboardRemoteDatasource {
  final Dio _dio;
  const DashboardRemoteDatasource(this._dio);

  Future<SuperadminDashboard> getSuperadmin() async {
    try {
      final resp = await _dio.get(ApiEndpoints.superadminDashboard);
      final data = resp.data['data'] ?? resp.data;
      return superadminDashboardFromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<DashboardSummaryModel> getSummary() async {
    try {
      final resp = await _dio.get(ApiEndpoints.dashboardSummary);
      final data = resp.data['data'] ?? resp.data;
      return DashboardSummaryModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
