import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../datasources/expenses_remote_datasource.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepositoryImpl(ref.read(expensesRemoteDatasourceProvider));
});

class ExpensesRepositoryImpl implements ExpensesRepository {
  final ExpensesRemoteDatasource _ds;
  const ExpensesRepositoryImpl(this._ds);

  @override
  Future<List<Expense>> getExpenses({
    int page = 1,
    int limit = 200,
    String? search,
    String? categoryId,
    String? unitId,
    DateTime? from,
    DateTime? to,
  }) =>
      _ds.getExpenses(
        page: page,
        limit: limit,
        search: search,
        categoryId: categoryId,
        unitId: unitId,
        from: from,
        to: to,
      );

  @override
  Future<Expense> getExpenseById(String id) => _ds.getExpenseById(id);

  @override
  Future<Expense> createExpense(Map<String, dynamic> body) => _ds.createExpense(body);

  @override
  Future<Expense> updateExpense(String id, Map<String, dynamic> body) =>
      _ds.updateExpense(id, body);

  @override
  Future<void> deleteExpense(String id, {String? companyId}) =>
      _ds.deleteExpense(id, companyId: companyId);
}
