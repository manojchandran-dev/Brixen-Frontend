import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/company_page.dart';
import '../../data/repositories/companies_repository_impl.dart';

final companiesProvider =
    AsyncNotifierProvider<CompaniesNotifier, List<Company>>(
      CompaniesNotifier.new,
    );

// Companies page search + status filter. Kept out of [companiesProvider] so
// other screens (Permissions, notification audience) always get every
// company. autoDispose: reset when the page closes, like its search box.
final companySearchProvider = StateProvider.autoDispose<String>((ref) => '');

/// The Companies page filters. Each field is null = "any".
class CompanyFilters {
  final bool? active;
  final String? onboarding, plan, industry;
  const CompanyFilters({
    this.active,
    this.onboarding,
    this.plan,
    this.industry,
  });

  /// How many filters are on — shown on the filter button.
  int get count =>
      [active, onboarding, plan, industry].where((v) => v != null).length;

  /// Status/plan/industry are filtered by the API; onboarding only here
  /// (the API has no param for it). Re-checking the API
  /// ones is harmless and keeps filtering right on an older backend.
  bool matches(Company c) =>
      (active == null || c.isActive == active) &&
      (onboarding == null || c.onboardingStatus == onboarding) &&
      (plan == null || c.subscriptionPlan == plan) &&
      (industry == null || c.industryType == industry);

  /// A filter only the app applies is on — the API total then no longer
  /// matches the rows shown.
  bool get hasLocalOnly => onboarding != null;

  /// `status` query value for the API.
  String? get statusParam =>
      active == null ? null : (active! ? 'ACTIVE' : 'INACTIVE');

  /// Copy with one field set (null clears it) — the filter sheet's
  /// sections are keyed by these names.
  CompanyFilters withField(String field, Object? value) => CompanyFilters(
    active: field == 'active' ? value as bool? : active,
    onboarding: field == 'onboarding' ? value as String? : onboarding,
    plan: field == 'plan' ? value as String? : plan,
    industry: field == 'industry' ? value as String? : industry,
  );
}

final companyFiltersProvider = StateProvider.autoDispose<CompanyFilters>(
  (ref) => const CompanyFilters(),
);

/// The Companies page list: `GET /companies` with the search box and the
/// status/plan/industry filters, done by the server across every company.
/// Loads [CompanyResultsNotifier.pageSize] at a time; the page calls
/// [CompanyResultsNotifier.loadMore] near the bottom for the next page.
/// Rebuilds (back to page 1) on each keystroke or chip, debounced so only
/// the last change after a 350ms pause hits the API, and after any
/// create/edit/delete/status change (see [CompaniesNotifier._publish]).
final companyResultsProvider =
    AsyncNotifierProvider.autoDispose<CompanyResultsNotifier, CompanyPage>(
      CompanyResultsNotifier.new,
    );

class CompanyResultsNotifier extends AutoDisposeAsyncNotifier<CompanyPage> {
  static const pageSize = 50;

  // Which page's search/filter state drives this list, and which endpoint
  // it calls — overridden by [PermissionCompaniesNotifier].
  AutoDisposeStateProvider<String> get searchProvider => companySearchProvider;
  AutoDisposeStateProvider<CompanyFilters> get filtersProvider =>
      companyFiltersProvider;
  bool get withAccess => false;

  String _query = '';
  ({String? status, String? plan, String? industry}) _f = (
    status: null,
    plan: null,
    industry: null,
  );
  int _page = 1;
  bool _loadingMore = false;
  // Bumped on every rebuild so a loadMore that started under the old
  // search/filters can't append its rows to the new list.
  int _generation = 0;

  @override
  Future<CompanyPage> build() async {
    _query = ref.watch(searchProvider).trim();
    _f = ref.watch(
      filtersProvider.select(
        (f) => (status: f.statusParam, plan: f.plan, industry: f.industry),
      ),
    );
    _page = 1;
    _generation++;

    var superseded = false;
    ref.onDispose(() => superseded = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (superseded) throw StateError('superseded');

    return _fetch(1);
  }

  Future<CompanyPage> _fetch(int page) => ref
      .read(companiesRepositoryProvider)
      .getCompanyPage(
        search: _query,
        status: _f.status,
        plan: _f.plan,
        industry: _f.industry,
        page: page,
        limit: pageSize,
        withAccess: withAccess,
      );

  /// Appends the next page. No-op while one is loading or when every
  /// match is already shown. A failure leaves the list as is; the next
  /// scroll retries.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null ||
        state.isLoading ||
        _loadingMore ||
        current.items.length >= current.total) {
      return;
    }
    _loadingMore = true;
    final generation = _generation;
    try {
      final next = await _fetch(_page + 1);
      if (generation != _generation) return;
      _page++;
      state = AsyncData(
        CompanyPage(
          items: [...current.items, ...next.items],
          // An empty page means nothing more, whatever the total said.
          total: next.items.isEmpty ? current.items.length : next.total,
          counts: current.counts,
        ),
      );
    } catch (_) {
      // Keep what's shown.
    } finally {
      _loadingMore = false;
    }
  }
}

// ── Permissions screen list ─────────────────────────────────────────────────

final permissionSearchProvider = StateProvider.autoDispose<String>((ref) => '');
final permissionFiltersProvider = StateProvider.autoDispose<CompanyFilters>(
  (ref) => const CompanyFilters(),
);

/// The Permissions screen's company list: `GET /permissions/companies` —
/// same search, filters and paging as the Companies page, plus each
/// company's Full/Custom/None counts (`Company.access`).
final permissionCompaniesProvider =
    AsyncNotifierProvider.autoDispose<PermissionCompaniesNotifier, CompanyPage>(
      PermissionCompaniesNotifier.new,
    );

class PermissionCompaniesNotifier extends CompanyResultsNotifier {
  @override
  AutoDisposeStateProvider<String> get searchProvider =>
      permissionSearchProvider;
  @override
  AutoDisposeStateProvider<CompanyFilters> get filtersProvider =>
      permissionFiltersProvider;
  @override
  bool get withAccess => true;
}

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

  // ── Multi-step creation ───────────────────────────────────────────────────

  /// Step 1: POST — creates the company, returns it with the server-generated id/code.
  Future<Company> createStep1(Company company) async {
    final created = await ref
        .read(companiesRepositoryProvider)
        .createCompany(company);
    _all = [..._all, created];
    _publish();
    return created;
  }

  /// Step 2: PUT /step2 — updates contact & owner info.
  Future<Company> updateStep2(String id, Company company) async {
    final updated = await ref
        .read(companiesRepositoryProvider)
        .updateCompanyStep2(id, company);
    _replace(updated);
    return updated;
  }

  /// Step 3: PUT /step3 — updates location info.
  Future<Company> updateStep3(String id, Company company) async {
    final updated = await ref
        .read(companiesRepositoryProvider)
        .updateCompanyStep3(id, company);
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
    _publish();
    // Re-sync with the server so the list reflects the delete authoritatively.
    // A failed refresh keeps the locally-pruned list — the delete itself succeeded.
    try {
      _all = await ref.read(companiesRepositoryProvider).getCompanies();
      _publish();
    } catch (_) {}
  }

  /// Soft-deleted companies, for the "Deleted companies" restore sheet.
  Future<List<Company>> fetchDeleted() => ref
      .read(companiesRepositoryProvider)
      .getCompanies(limit: 100, deleted: true);

  /// Undo of a (soft) delete — brings back the company and everything that
  /// was deleted with it, then re-syncs the list.
  Future<void> restoreCompany(String id) async {
    await ref.read(companiesRepositoryProvider).restoreCompany(id);
    _all = await ref.read(companiesRepositoryProvider).getCompanies();
    _publish();
  }

  /// Returns null on success, or an error message string on failure.
  /// Flips [company]'s status. Returns null on success, or an error message.
  /// Takes the company itself: the Companies page lists API results, which
  /// may not be in this shared list yet.
  Future<String?> toggleStatus(Company company) async {
    final idx = _all.indexWhere((c) => c.id == company.id);
    final original = idx == -1 ? null : _all[idx];
    // Optimistic update of the shared list (not published to the page's
    // list — that reloads only once the server confirms).
    if (original != null) {
      _all = List.from(_all)
        ..[idx] = original.copyWith(isActive: !original.isActive);
      state = AsyncData(List.from(_all));
    }
    try {
      final updated = await ref
          .read(companiesRepositoryProvider)
          .updateCompanyStatus(company.id, !company.isActive);
      _replace(updated);
      return null;
    } catch (e) {
      // Revert on failure (includes 400 from backend when onboarding incomplete)
      if (original != null) {
        _all = List.from(_all)..[idx] = original;
        state = AsyncData(List.from(_all));
      }
      return e.toString();
    }
  }

  void _replace(Company updated) {
    _all = _all.map((c) => c.id == updated.id ? updated : c).toList();
    _publish();
  }

  /// Publishes a server-confirmed change: updates this shared list and
  /// reloads the Companies page's list.
  void _publish() {
    state = AsyncData(List.from(_all));
    ref.invalidate(companyResultsProvider);
    ref.invalidate(permissionCompaniesProvider);
  }
}
