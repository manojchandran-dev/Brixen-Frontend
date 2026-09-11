import 'package:equatable/equatable.dart';

class MasterItem extends Equatable {
  final String id;
  final String typeKey;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  // For assignable types (e.g. masterMenu): which company category this belongs to
  final String? assignedCategoryId;
  final String? assignedCategoryName;
  // Unit type only: e.g. name="pcs", fullForm="Pieces", description="Number of garments"
  final String? fullForm;

  const MasterItem({
    required this.id,
    required this.typeKey,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
    this.assignedCategoryId,
    this.assignedCategoryName,
    this.fullForm,
  });

  MasterItem copyWith({
    String? name,
    String? description,
    bool? isActive,
    String? assignedCategoryId,
    String? assignedCategoryName,
    String? fullForm,
  }) => MasterItem(
    id: id,
    typeKey: typeKey,
    name: name ?? this.name,
    description: description ?? this.description,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
    assignedCategoryId: assignedCategoryId ?? this.assignedCategoryId,
    assignedCategoryName: assignedCategoryName ?? this.assignedCategoryName,
    fullForm: fullForm ?? this.fullForm,
  );

  @override
  List<Object?> get props => [
    id,
    typeKey,
    name,
    isActive,
    createdAt,
    assignedCategoryId,
  ];

  /// Human-readable reference code shown in the UI.
  String? get displayCode => codeFor(typeKey, id);

  static String? codeFor(String typeKey, String id) {
    switch (typeKey) {
      case 'expenseCategory':
        // Backend id is a plain sequential integer — pad it ourselves.
        final n = int.tryParse(id);
        return n == null ? null : 'EXCAT${n.toString().padLeft(11, '0')}';
      case 'companyCategory':
        // Backend id is already the formatted code, e.g. "COCAT65618502479".
        return id;
      case 'productCategory':
        // Backend id is already the formatted code, e.g. "PRCAT65618502479".
        return id;
      case 'unit':
        // Backend id is already the formatted code, e.g. "UNIT533111998460".
        return id;
      default:
        return null;
    }
  }
}
