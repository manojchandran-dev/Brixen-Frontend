import 'package:equatable/equatable.dart';
import '../../domain/entities/company_category.dart';

abstract class CompanyCategoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CompanyCategoryLoading extends CompanyCategoryState {}

class CompanyCategoryLoaded extends CompanyCategoryState {
  final List<CompanyCategory> items;
  final String query;

  CompanyCategoryLoaded({required this.items, this.query = ''});

  List<CompanyCategory> get filtered => query.isEmpty
      ? items
      : items
            .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

  @override
  List<Object?> get props => [items, query];
}
