import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/super_admin_company_filter_provider.dart';
import '../../../masters/presentation/cubit/master_cubit.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expenses_repository_impl.dart';
import '../../domain/entities/expense.dart';

final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(
  ExpensesNotifier.new,
);

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  List<Expense> _all = [];

  @override
  Future<List<Expense>> build() async {
    ref.watch(superAdminCompanyFilterProvider);
    // Ensure category/unit master data is cached so names can be resolved.
    await masterCubit.load('expenseCategory');
    await masterCubit.load('unit');
    final list = await ref.read(expensesRepositoryProvider).getExpenses();
    _all = _resolveNames(list);
    return _all;
  }

  /// The API only returns `category_id`/`unit_id` — fills in the display
  /// names client-side from the already-loaded Masters data.
  List<Expense> _resolveNames(List<Expense> list) {
    final categories = {for (final c in masterCubit.allItemsOfType('expenseCategory')) c.id: c.name};
    final units = {for (final u in masterCubit.allItemsOfType('unit')) u.id: u.name};
    return list.map((e) => Expense(
      id: e.id,
      categoryId: e.categoryId,
      category: categories[e.categoryId] ?? e.categoryId,
      unitId: e.unitId,
      unit: e.unitId != null ? units[e.unitId] : null,
      title: e.title,
      amount: e.amount,
      expenseDate: e.expenseDate,
      paymentMethod: e.paymentMethod,
      receiptImagePath: e.receiptImagePath,
      notes: e.notes,
      createdAt: e.createdAt,
    )).toList();
  }

  Future<Expense> addExpense(Expense expense, {required String companyId}) async {
    final created = await ref
        .read(expensesRepositoryProvider)
        .createExpense(ExpenseModel.toBody(expense, companyId: companyId));
    _all = _resolveNames([..._all, created]);
    state = AsyncData(List.from(_all));
    return created;
  }

  Future<Expense> updateExpense(Expense expense, {String? companyId}) async {
    final updated = await ref
        .read(expensesRepositoryProvider)
        .updateExpense(expense.id, ExpenseModel.toBody(expense, companyId: companyId));
    _all = _resolveNames(_all.map((e) => e.id == updated.id ? updated : e).toList());
    state = AsyncData(List.from(_all));
    return updated;
  }

  Future<void> deleteExpense(String id, {String? companyId}) async {
    await ref.read(expensesRepositoryProvider).deleteExpense(id, companyId: companyId);
    _all = _all.where((e) => e.id != id).toList();
    state = AsyncData(List.from(_all));
  }
}
