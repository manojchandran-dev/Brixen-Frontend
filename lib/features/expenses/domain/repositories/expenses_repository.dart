import '../entities/expense.dart';

abstract class ExpensesRepository {
  Future<List<Expense>> getExpenses({
    int page = 1,
    int limit = 200,
    String? search,
    String? categoryId,
    String? unitId,
    DateTime? from,
    DateTime? to,
  });
  Future<Expense> getExpenseById(String id);
  Future<Expense> createExpense(Map<String, dynamic> body);
  Future<Expense> updateExpense(String id, Map<String, dynamic> body);
  Future<void> deleteExpense(String id, {String? companyId});
}
