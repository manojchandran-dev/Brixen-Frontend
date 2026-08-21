import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/expense_model.dart';

final expensesRemoteDatasourceProvider = Provider<ExpensesRemoteDatasource>((ref) {
  return ExpensesRemoteDatasource(ref.read(dioProvider));
});

class ExpensesRemoteDatasource {
  final Dio _dio;
  const ExpensesRemoteDatasource(this._dio);

  Future<List<ExpenseModel>> getExpenses({
    int page = 1,
    int limit = 200,
    String? search,
    String? categoryId,
    String? unitId,
  }) async {
    try {
      final resp = await _dio.get(ApiEndpoints.expenses, queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null) 'category_id': categoryId,
        if (unitId != null) 'unit_id': unitId,
      });
      final data = resp.data['data'] ?? resp.data;
      final list = (data is List) ? data : (data['items'] ?? []);
      return (list as List)
          .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ExpenseModel> getExpenseById(String id) async {
    try {
      final resp = await _dio.get(ApiEndpoints.expenseById(id));
      final data = resp.data['data'] ?? resp.data;
      return ExpenseModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ExpenseModel> createExpense(Map<String, dynamic> body) async {
    try {
      final resp = await _dio.post(ApiEndpoints.expenses, data: body);
      final data = resp.data['data'] ?? resp.data;
      return ExpenseModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ExpenseModel> updateExpense(String id, Map<String, dynamic> body) async {
    try {
      final resp = await _dio.put(ApiEndpoints.expenseById(id), data: body);
      final data = resp.data['data'] ?? resp.data;
      return ExpenseModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _dio.delete(ApiEndpoints.expenseById(id));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
