class Expense {
  final String id;
  final String category;
  final String title;
  final double amount;
  final DateTime expenseDate;
  final String? paymentMethod;
  final String? receiptImagePath;
  final String? notes;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.category,
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
    String? category,
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
      category: category ?? this.category,
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
