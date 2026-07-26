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

  const MasterItem({
    required this.id,
    required this.typeKey,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
    this.assignedCategoryId,
    this.assignedCategoryName,
  });

  MasterItem copyWith({
    String? name,
    String? description,
    bool? isActive,
    String? assignedCategoryId,
    String? assignedCategoryName,
  }) =>
      MasterItem(
        id: id,
        typeKey: typeKey,
        name: name ?? this.name,
        description: description ?? this.description,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        assignedCategoryId: assignedCategoryId ?? this.assignedCategoryId,
        assignedCategoryName: assignedCategoryName ?? this.assignedCategoryName,
      );

  @override
  List<Object?> get props => [id, typeKey, name, isActive, createdAt, assignedCategoryId];
}
