import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/expense.dart';

final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(
  ExpensesNotifier.new,
);

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  List<Expense> _all = [];

  @override
  Future<List<Expense>> build() async {
    _all = [];
    return _all;
  }

  Future<void> addExpense(Expense expense) async {
    _all = [..._all, expense];
    state = AsyncData(List.from(_all));
  }

  Future<void> updateExpense(Expense updated) async {
    _all = _all.map((e) => e.id == updated.id ? updated : e).toList();
    state = AsyncData(List.from(_all));
  }

  Future<void> deleteExpense(String id) async {
    _all = _all.where((e) => e.id != id).toList();
    state = AsyncData(List.from(_all));
  }
}
