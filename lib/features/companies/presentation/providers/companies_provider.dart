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

  /// Fetches full details for a single company (used by the "View" action).
  Future<Company> fetchCompanyDetail(String id) =>
      ref.read(companiesRepositoryProvider).getCompanyById(id);

  void search(String query) {
    final q = query.trim().toLowerCase();
    state = AsyncData(
      q.isEmpty
          ? _all
          : _all
              .where((c) =>
                  c.name.toLowerCase().contains(q) ||
                  (c.email?.toLowerCase().contains(q) ?? false) ||
                  (c.code?.toLowerCase().contains(q) ?? false))
              .toList(),
    );
  }

  // ── Multi-step creation ───────────────────────────────────────────────────

  /// Step 1: POST — creates the company, returns it with the server-generated id/code.
  Future<Company> createStep1(Company company) async {
    final created = await ref.read(companiesRepositoryProvider).createCompany(company);
    _all = [..._all, created];
    state = AsyncData(List.from(_all));
    return created;
  }

  /// Step 2: PUT /step2 — updates contact & owner info.
  Future<Company> updateStep2(String id, Company company) async {
    final updated =
        await ref.read(companiesRepositoryProvider).updateCompanyStep2(id, company);
    _replace(updated);
    return updated;
  }

  /// Step 3: PUT /step3 — updates location info.
  Future<Company> updateStep3(String id, Company company) async {
    final updated =
        await ref.read(companiesRepositoryProvider).updateCompanyStep3(id, company);
    _replace(updated);
    return updated;
  }

  // ── General mutations ─────────────────────────────────────────────────────

  Future<void> updateCompany(Company company) async {
    final updated = await ref
        .read(companiesRepositoryProvider)
        .updateCompany(company.id, company);
    _replace(updated);
  }

  Future<void> deleteCompany(String id) async {
    await ref.read(companiesRepositoryProvider).deleteCompany(id);
    _all = _all.where((c) => c.id != id).toList();
    state = AsyncData(List.from(_all));
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> toggleStatus(String id) async {
    final idx = _all.indexWhere((c) => c.id == id);
    if (idx == -1) return null;
    final original = _all[idx];
    // Optimistic update
    _all = List.from(_all)..[idx] = original.copyWith(isActive: !original.isActive);
    state = AsyncData(List.from(_all));
    try {
      final updated = await ref
          .read(companiesRepositoryProvider)
          .updateCompanyStatus(id, !original.isActive);
      _replace(updated);
      return null;
    } catch (e) {
      // Revert on failure (includes 400 from backend when onboarding incomplete)
      _all = List.from(_all)..[idx] = original;
      state = AsyncData(List.from(_all));
      return e.toString();
    }
  }

  void _replace(Company updated) {
    _all = _all.map((c) => c.id == updated.id ? updated : c).toList();
    state = AsyncData(List.from(_all));
  }
}
