import '../entities/master_item.dart';

/// One repository, keyed by `typeKey`, rather than four near-identical
/// interfaces — [MasterCubit] already treats every remote-backed master
/// type uniformly through the same [RemoteMasterDatasource] shape, so this
/// mirrors that exactly instead of adding four copies of the same 5 methods.
abstract class MastersRepository {
  bool isRemote(String typeKey);
  Future<List<MasterItem>> getAll(String typeKey, {int page = 1, int limit = 100, String? search});
  Future<MasterItem> getById(String typeKey, String id);
  Future<MasterItem> create(
    String typeKey, {
    required String name,
    String? description,
    String? fullForm,
    bool isActive = true,
    required String companyId,
  });
  Future<MasterItem> update(
    String typeKey,
    String id, {
    String? name,
    String? description,
    String? fullForm,
    bool? isActive,
  });
  Future<void> delete(String typeKey, String id);
}
