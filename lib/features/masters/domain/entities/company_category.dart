import 'package:equatable/equatable.dart';

class CompanyCategory extends Equatable {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const CompanyCategory({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
  });

  CompanyCategory copyWith({String? name, String? description, bool? isActive}) =>
      CompanyCategory(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, name, isActive, createdAt];
}
