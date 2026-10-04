import 'package:brixen/features/masters/domain/entities/master_item.dart';
import 'package:brixen/features/masters/domain/repositories/masters_repository.dart';
import 'package:brixen/features/masters/presentation/cubit/master_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts list fetches per master type.
class _Repo extends Fake implements MastersRepository {
  final calls = <String, int>{};

  @override
  bool isRemote(String typeKey) => true;

  @override
  Future<List<MasterItem>> getAll(
    String typeKey, {
    int page = 1,
    int limit = 100,
    String? search,
  }) async {
    calls[typeKey] = (calls[typeKey] ?? 0) + 1;
    await Future<void>.value(); // async, like a real request
    return [
      MasterItem(id: '1', typeKey: typeKey, name: 'Kg', createdAt: DateTime(2026)),
    ];
  }
}

void main() {
  test('ensureLoaded: one shared request, then the cache', () async {
    final repo = _Repo();
    final cubit = MasterCubit(repo);
    addTearDown(cubit.close);

    // Expenses and Products both need units at the same time.
    await Future.wait([cubit.ensureLoaded('unit'), cubit.ensureLoaded('unit')]);
    expect(repo.calls['unit'], 1);
    expect(cubit.allItemsOfType('unit').single.name, 'Kg');

    // Later refreshes reuse the cache.
    await cubit.ensureLoaded('unit');
    expect(repo.calls['unit'], 1);

    // The Masters page's own load still fetches fresh.
    await cubit.load('unit');
    expect(repo.calls['unit'], 2);
  });
}
