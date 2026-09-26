import 'package:brixen/features/masters/domain/entities/master_item.dart';
import 'package:brixen/features/masters/domain/repositories/masters_repository.dart';
import 'package:brixen/features/masters/presentation/cubit/master_cubit.dart';
import 'package:brixen/features/masters/presentation/cubit/master_state.dart';
import 'package:flutter_test/flutter_test.dart';

MasterItem _item(String id, String name, String desc) => MasterItem(
      id: id,
      typeKey: 'companyCategory',
      name: name,
      description: desc,
      createdAt: DateTime(2026),
    );

/// Fake GET /company-categories: `search` matches name or description.
class _Repo implements MastersRepository {
  final all = [
    _item('1', 'Retailer', 'Retailer business type'),
    _item('2', 'Wholesaler', 'Wholesaler business type'),
    _item('3', 'thread', ''),
  ];
  final searches = <String?>[];

  @override
  bool isRemote(String typeKey) => true;

  @override
  Future<List<MasterItem>> getAll(String typeKey, {int page = 1, int limit = 100, String? search}) async {
    searches.add(search);
    if (search == null) return all;
    final q = search.toLowerCase();
    return all
        .where((i) => i.name.toLowerCase().contains(q) || (i.description ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

List<String> _names(MasterCubit c) => (c.state as MasterLoaded).filtered.map((i) => i.name).toList();

void main() {
  test('search: name matches at once, then the server result (description matches too)', () async {
    final repo = _Repo();
    final cubit = MasterCubit(repo);
    addTearDown(cubit.close);
    await cubit.load('companyCategory');

    cubit.search('business');
    // Instant local filter is name-only → nothing yet.
    expect(_names(cubit), isEmpty);

    await Future<void>.delayed(const Duration(milliseconds: 450));
    // Server matched the descriptions.
    expect(_names(cubit), ['Retailer', 'Wholesaler']);
    expect(repo.searches, [null, 'business']);
    // Dropdowns elsewhere still get the full list.
    expect(cubit.itemsOfType('companyCategory'), hasLength(3));

    cubit.search('');
    expect(_names(cubit), ['Retailer', 'Wholesaler', 'thread']);
  });

  test('fast typing sends only the last query', () async {
    final repo = _Repo();
    final cubit = MasterCubit(repo);
    addTearDown(cubit.close);
    await cubit.load('companyCategory');

    for (final q in ['t', 'th', 'thr']) {
      cubit.search(q);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    await Future<void>.delayed(const Duration(milliseconds: 450));

    expect(repo.searches, [null, 'thr']);
    expect(_names(cubit), ['thread']);
  });
}
