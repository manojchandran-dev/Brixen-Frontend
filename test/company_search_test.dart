import 'package:brixen/features/companies/data/repositories/companies_repository_impl.dart';
import 'package:brixen/features/companies/domain/entities/company.dart';
import 'package:brixen/features/companies/domain/entities/company_page.dart';
import 'package:brixen/features/companies/domain/repositories/companies_repository.dart';
import 'package:brixen/features/companies/presentation/providers/companies_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every Companies-page request the app sends to the API.
class _FakeRepo implements CompaniesRepository {
  final calls = <String>[];
  final pages = <int>[];
  var sharedListLoads = 0;
  /// How many companies the fake server has in total.
  int serverTotal = 1;

  @override
  Future<List<Company>> getCompanies({int page = 1, int limit = 50, String? search, bool deleted = false}) async {
    sharedListLoads++;
    return const [];
  }

  @override
  Future<CompanyPage> getCompanyPage({String? search, String? status, String? plan, String? industry, int page = 1, int limit = 50, bool withAccess = false}) async {
    calls.add('search=$search status=$status plan=$plan industry=$industry');
    pages.add(page);
    final start = (page - 1) * limit;
    final count = (serverTotal - start).clamp(0, limit);
    return CompanyPage(
      items: [
        for (var i = 0; i < count; i++)
          Company(id: '${start + i}', name: serverTotal == 1 ? 'Kaveri Textiles' : 'Co ${start + i}', ownerName: '', createdAt: DateTime(2026)),
      ],
      total: serverTotal,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

(ProviderContainer, _FakeRepo) _setup() {
  final repo = _FakeRepo();
  final container = ProviderContainer(overrides: [
    companiesRepositoryProvider.overrideWithValue(repo),
  ]);
  container.listen(companyResultsProvider, (_, _) {});
  return (container, repo);
}

void main() {
  test('opening the page loads one page of 50 and nothing else', () async {
    final (container, repo) = _setup();
    addTearDown(container.dispose);
    repo.serverTotal = 120;

    final page = await container.read(companyResultsProvider.future);

    expect(page.items, hasLength(50));
    expect(repo.pages, [1]);
    expect(repo.sharedListLoads, 0, reason: 'no extra limit=50 shared-list request');
  });

  test('loadMore appends 50 at a time and stops at the total', () async {
    final (container, repo) = _setup();
    addTearDown(container.dispose);
    repo.serverTotal = 120;
    await container.read(companyResultsProvider.future);
    final notifier = container.read(companyResultsProvider.notifier);

    await notifier.loadMore();
    await notifier.loadMore();
    await notifier.loadMore(); // all 120 shown — must not call the API

    expect(container.read(companyResultsProvider).value!.items, hasLength(120));
    expect(repo.pages, [1, 2, 3]);
  });

  test('concurrent loadMore calls fetch the next page only once', () async {
    final (container, repo) = _setup();
    addTearDown(container.dispose);
    repo.serverTotal = 120;
    await container.read(companyResultsProvider.future);
    final notifier = container.read(companyResultsProvider.notifier);

    await Future.wait([notifier.loadMore(), notifier.loadMore(), notifier.loadMore()]);

    expect(repo.pages, [1, 2]);
  });

  test('typing is debounced: only the last query reaches the API', () async {
    final (container, repo) = _setup();
    addTearDown(container.dispose);

    for (final q in ['k', 'ka', 'kav']) {
      container.read(companySearchProvider.notifier).state = q;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final page = await container.read(companyResultsProvider.future);

    expect(repo.calls, ['search=kav status=null plan=null industry=null']);
    expect(page.items.single.name, 'Kaveri Textiles');
  });

  test('status/plan/industry chips go to the API; onboarding stays local', () async {
    final (container, repo) = _setup();
    addTearDown(container.dispose);

    container.read(companyFiltersProvider.notifier).state = const CompanyFilters()
        .withField('active', false)
        .withField('plan', 'PRO')
        .withField('industry', 'Garments')
        .withField('onboarding', 'completed');
    await container.read(companyResultsProvider.future);

    expect(repo.calls, ['search= status=INACTIVE plan=PRO industry=Garments']);
    expect(container.read(companyFiltersProvider).hasLocalOnly, isTrue);
  });

  test('filters combine, and clearing one widens the result', () {
    Company co(String id, {bool active = true, String? plan, String? onboarding}) =>
        Company(id: id, name: id, ownerName: '', isActive: active,
            subscriptionPlan: plan, onboardingStatus: onboarding, createdAt: DateTime(2026));
    final list = [
      co('a', plan: 'PRO', onboarding: 'completed'),
      co('b', active: false, plan: 'PRO', onboarding: 'pending'),
      co('c', plan: 'FREE', onboarding: 'completed'),
    ];
    var f = const CompanyFilters().withField('plan', 'PRO').withField('active', true);
    expect(list.where(f.matches).map((c) => c.id), ['a']);
    expect(f.count, 2);
    f = f.withField('active', null);
    expect(list.where(f.matches).map((c) => c.id), ['a', 'b']);
  });
}
