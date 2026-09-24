import '../../domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    super.companyId,
    required super.categoryId,
    required super.category,
    super.unitId,
    super.unit,
    required super.title,
    required super.amount,
    required super.expenseDate,
    super.paymentMethod,
    super.receiptImagePath,
    super.notes,
    required super.createdAt,
  });

  /// `category`/`unit` (display names) aren't returned by the API — they're
  /// resolved client-side afterward from the already-loaded Masters data.
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'].toString(),
      companyId: json['company_id']?.toString(),
      categoryId: (json['category_id'] ?? '').toString(),
      category: '',
      unitId: json['unit_id']?.toString(),
      unit: null,
      title: (json['title'] ?? '').toString(),
      // Backend serializes amount as a string (e.g. "5000").
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      expenseDate: json['expense_date'] != null
          ? DateTime.tryParse(json['expense_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      paymentMethod: json['payment_method'],
      receiptImagePath: json['receipt_url'],
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Request body for create/update. `unit_id` is always included (as null
  /// when unset) since the caller always submits full current form state —
  /// this doubles as how the backend expects a unit to be cleared on PUT.
  /// `receipt_url` must already be a hosted URL — the page uploads a picked
  /// receipt via `POST /uploads` before submitting.
  static Map<String, dynamic> toBody(Expense e, {String? companyId}) => {
        if (companyId != null) 'company_id': int.parse(companyId),
        'category_id': e.categoryId,
        'title': e.title,
        'amount': e.amount,
        'unit_id': e.unitId,
        'expense_date': e.expenseDate.toIso8601String(),
        if (e.paymentMethod != null && e.paymentMethod!.isNotEmpty) 'payment_method': e.paymentMethod,
        if (e.notes != null && e.notes!.isNotEmpty) 'notes': e.notes,
        'receipt_url': e.receiptImagePath,
      };
}
