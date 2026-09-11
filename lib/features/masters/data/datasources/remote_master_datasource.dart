import '../../domain/entities/master_item.dart';

/// Common shape for master types backed by a real "simple list" API —
/// e.g. expense categories, company categories, units. Lets [MasterCubit]
/// treat any such type uniformly instead of hardcoding one type at a time.
/// Not every implementation uses every field: [isActive] is meaningless for
/// types with no status concept (e.g. units), and [fullForm] is meaningless
/// for types with no such column (e.g. categories) — implementations just
/// ignore what doesn't apply to them.
abstract class RemoteMasterDatasource {
  Future<List<MasterItem>> getAll({
    int page = 1,
    int limit = 100,
    String? search,
  });

  Future<MasterItem> getById(String id);

  Future<MasterItem> create({
    required String name,
    String? description,
    String? fullForm,
    bool isActive = true,
    required String companyId,
  });

  Future<MasterItem> update(
    String id, {
    String? name,
    String? description,
    String? fullForm,
    bool? isActive,
  });

  Future<void> delete(String id);
}
