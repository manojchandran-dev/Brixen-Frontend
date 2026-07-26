import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/company.dart';
import '../../data/repositories/companies_repository_impl.dart';

final companiesProvider = AsyncNotifierProvider<CompaniesNotifier, List<Company>>(
  CompaniesNotifier.new,
);

class CompaniesNotifier extends AsyncNotifier<List<Company>> {
  List<Company> _all = [];

  @override
  Future<List<Company>> build() async {
    _all = await ref.read(companiesRepositoryProvider).getCompanies();
    return _all;
  }

  void search(String query) {
    final q = query.trim().toLowerCase();
    state = AsyncData(
      q.isEmpty
          ? _all
          : _all
              .where((c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.email.toLowerCase().contains(q))
              .toList(),
    );
  }

  Future<void> addCompany(Company company) async {
    try {
      final created =
          await ref.read(companiesRepositoryProvider).createCompany(company);
      _all = [..._all, created];
      state = AsyncData(List.from(_all));
    } catch (_) {
      // optimistic fallback: add locally
      _all = [..._all, company];
      state = AsyncData(List.from(_all));
    }
  }

  Future<void> updateCompany(Company company) async {
    try {
      final updated = await ref
          .read(companiesRepositoryProvider)
          .updateCompany(company.id, company);
      _all = _all.map((c) => c.id == company.id ? updated : c).toList();
      state = AsyncData(List.from(_all));
    } catch (_) {
      _all = _all.map((c) => c.id == company.id ? company : c).toList();
      state = AsyncData(List.from(_all));
    }
  }

  Future<void> deleteCompany(String id) async {
    try {
      await ref.read(companiesRepositoryProvider).deleteCompany(id);
    } catch (_) {}
    _all = _all.where((c) => c.id != id).toList();
    state = AsyncData(List.from(_all));
  }

  Future<void> toggleStatus(String id) async {
    final idx = _all.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    final toggled = _all[idx].copyWith(isActive: !_all[idx].isActive);
    _all = List.from(_all)..[idx] = toggled;
    state = AsyncData(List.from(_all));
    try {
      await ref.read(companiesRepositoryProvider).updateCompany(id, toggled);
    } catch (_) {
      // revert on error
      final original = _all[idx];
      _all = List.from(_all)..[idx] = original.copyWith(isActive: !original.isActive);
      state = AsyncData(List.from(_all));
    }
  }
}
