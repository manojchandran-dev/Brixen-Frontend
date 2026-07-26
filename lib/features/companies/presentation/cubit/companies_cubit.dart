import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/company.dart';
import 'companies_state.dart';

// Global singleton so Create page shares the same state as the list
final companiesCubit = CompaniesCubit();

class CompaniesCubit extends Cubit<CompaniesState> {
  CompaniesCubit() : super(CompaniesInitial());

  static const int _perPage = 5;

  static final List<Company> _mockData = [
    Company(id: '1', name: 'Alpha Corp',    code: 'ALPHA', ownerName: 'John Smith',    email: 'alpha@example.com',   subscriptionPlan: 'Enterprise',    isActive: true,  createdAt: DateTime(2025, 12, 15)),
    Company(id: '2', name: 'Beta Company',  code: 'BETA',  ownerName: 'Jane Doe',      email: 'beta@example.com',    subscriptionPlan: 'Professional',  isActive: true,  createdAt: DateTime(2026,  1, 20)),
    Company(id: '3', name: 'Core Group',    code: 'CORE',  ownerName: 'Bob Johnson',   email: 'core@example.com',    subscriptionPlan: 'Basic',         isActive: false, createdAt: DateTime(2026,  2, 10)),
    Company(id: '4', name: 'Delta Goods',   code: 'DELTA', ownerName: 'Alice Brown',   email: 'delta@example.com',   subscriptionPlan: 'Professional',  isActive: true,  createdAt: DateTime(2026,  2, 25)),
    Company(id: '5', name: 'Epsilon Inc',   code: 'EPS',   ownerName: 'Charlie Davis', email: 'epsilon@example.com', subscriptionPlan: 'Basic',         isActive: true,  createdAt: DateTime(2026,  3, 14)),
    Company(id: '6', name: 'Zeta Ltd',      code: 'ZETA',  ownerName: 'David Wilson',  email: 'zeta@example.com',    subscriptionPlan: 'Professional',  isActive: true,  createdAt: DateTime(2026,  3, 28)),
    Company(id: '7', name: 'Eta Systems',   code: 'ETA',   ownerName: 'Eva Martinez',  email: 'eta@example.com',     subscriptionPlan: 'Enterprise',    isActive: false, createdAt: DateTime(2026,  4,  8)),
    Company(id: '8', name: 'Theta Corp',    code: 'THETA', ownerName: 'Frank Garcia',  email: 'theta@example.com',   subscriptionPlan: 'Standard',      isActive: true,  createdAt: DateTime(2026,  5,  3)),
  ];

  List<Company> _companies = List.from(_mockData);

  void load() {
    emit(CompaniesLoading());
    Future.delayed(const Duration(milliseconds: 400), () {
      _emitLoaded(_companies, query: '', page: 1);
    });
  }

  void search(String query) {
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _companies
        : _companies.where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q) ||
            (c.code?.toLowerCase().contains(q) ?? false)).toList();
    _emitLoaded(filtered, query: query, page: 1);
  }

  void goToPage(int page) {
    if (state is CompaniesLoaded) {
      final s = state as CompaniesLoaded;
      _emitLoaded(s.all, query: s.query, page: page);
    }
  }

  void addCompany(Company company) {
    _companies = [company, ..._companies];
    if (state is CompaniesLoaded) {
      final s = state as CompaniesLoaded;
      _emitLoaded(_companies, query: s.query, page: 1);
    }
  }

  void deleteCompany(String id) {
    _companies = _companies.where((c) => c.id != id).toList();
    if (state is CompaniesLoaded) {
      final s = state as CompaniesLoaded;
      _emitLoaded(_companies, query: s.query, page: s.currentPage);
    }
  }

  void toggleStatus(String id) {
    _companies = _companies.map((c) =>
        c.id == id ? c.copyWith(isActive: !c.isActive) : c).toList();
    if (state is CompaniesLoaded) {
      final s = state as CompaniesLoaded;
      _emitLoaded(_companies, query: s.query, page: s.currentPage);
    }
  }

  void _emitLoaded(List<Company> all, {required String query, required int page}) {
    final totalPages = (all.length / _perPage).ceil().clamp(1, 999);
    final safePage = page.clamp(1, totalPages);
    final start = (safePage - 1) * _perPage;
    final end = (start + _perPage).clamp(0, all.length);
    emit(CompaniesLoaded(
      all: all,
      paged: all.sublist(start, end),
      query: query,
      currentPage: safePage,
      totalPages: totalPages,
    ));
  }
}
