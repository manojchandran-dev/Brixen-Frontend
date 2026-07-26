import 'package:equatable/equatable.dart';
import '../../domain/entities/company.dart';

abstract class CompaniesState extends Equatable {
  const CompaniesState();
  @override
  List<Object?> get props => [];
}

class CompaniesInitial extends CompaniesState {}

class CompaniesLoading extends CompaniesState {}

class CompaniesLoaded extends CompaniesState {
  final List<Company> all;
  final List<Company> paged;
  final String query;
  final int currentPage;
  final int totalPages;
  final int perPage;

  const CompaniesLoaded({
    required this.all,
    required this.paged,
    required this.query,
    required this.currentPage,
    required this.totalPages,
    this.perPage = 5,
  });

  CompaniesLoaded copyWith({
    List<Company>? all,
    List<Company>? paged,
    String? query,
    int? currentPage,
    int? totalPages,
  }) =>
      CompaniesLoaded(
        all: all ?? this.all,
        paged: paged ?? this.paged,
        query: query ?? this.query,
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        perPage: perPage,
      );

  @override
  List<Object?> get props => [all, paged, query, currentPage, totalPages];
}

class CompaniesError extends CompaniesState {
  final String message;
  const CompaniesError(this.message);
  @override
  List<Object?> get props => [message];
}
