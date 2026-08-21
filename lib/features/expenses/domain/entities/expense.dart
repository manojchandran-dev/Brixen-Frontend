class Expense {
  final String id;
  final String categoryId;
  final String category; // display name, resolved client-side from Masters
  final String? unitId;
  final String? unit; // display name, resolved client-side from Masters
  final String title;
  final double amount;
  final DateTime expenseDate;
  final String? paymentMethod;
  final String? receiptImagePath;
  final String? notes;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.categoryId,
    required this.category,
    this.unitId,
    this.unit,
    required this.title,
    required this.amount,
    required this.expenseDate,
    this.paymentMethod,
    this.receiptImagePath,
    this.notes,
    required this.createdAt,
  });

  Expense copyWith({
    String? id,
    String? categoryId,
    String? category,
    String? unitId,
    String? unit,
    String? title,
    double? amount,
    DateTime? expenseDate,
    String? paymentMethod,
    String? receiptImagePath,
    String? notes,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      unitId: unitId ?? this.unitId,
      unit: unit ?? this.unit,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
