import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/date_utils.dart';
import '../models/reports_summary_model.dart';

final reportsRemoteDatasourceProvider = Provider<ReportsRemoteDatasource>((
  ref,
) {
  return ReportsRemoteDatasource(ref.read(dioProvider));
});

class ReportsRemoteDatasource {
  final Dio _dio;
  const ReportsRemoteDatasource(this._dio);

  Future<ReportsSummaryModel> getSummary({
    required String period, // 'weekly' | 'monthly' | 'yearly' | 'custom'
    DateTime? from,
    DateTime? to,
    int topCategoriesLimit = 5,
    int topCustomersLimit = 5,
  }) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.reportsSummary,
        queryParameters: {
          'period': period,
          if (from != null) 'from': toIsoDateOnly(from),
          if (to != null) 'to': toIsoDateOnly(to),
          'top_categories_limit': topCategoriesLimit,
          'top_customers_limit': topCustomersLimit,
        },
      );
      final data = resp.data['data'] ?? resp.data;
      return ReportsSummaryModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
