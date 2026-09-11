import '../../domain/entities/master_item.dart';
import '../../domain/repositories/masters_repository.dart';
import '../datasources/remote_master_datasource.dart';

class MastersRepositoryImpl implements MastersRepository {
  final Map<String, RemoteMasterDatasource> _remoteDatasources;
  const MastersRepositoryImpl(this._remoteDatasources);

  RemoteMasterDatasource? _remoteFor(String typeKey) => _remoteDatasources[typeKey];

  @override
  bool isRemote(String typeKey) => _remoteFor(typeKey) != null;

  @override
  Future<List<MasterItem>> getAll(String typeKey, {int page = 1, int limit = 100, String? search}) {
    final remote = _remoteFor(typeKey);
    if (remote == null) throw StateError('"$typeKey" is not a remote-backed master type');
    return remote.getAll(page: page, limit: limit, search: search);
  }

  @override
  Future<MasterItem> getById(String typeKey, String id) {
    final remote = _remoteFor(typeKey);
    if (remote == null) throw StateError('"$typeKey" is not a remote-backed master type');
    return remote.getById(id);
  }

  @override
  Future<MasterItem> create(
    String typeKey, {
    required String name,
    String? description,
    String? fullForm,
    bool isActive = true,
    required String companyId,
  }) {
    final remote = _remoteFor(typeKey);
    if (remote == null) throw StateError('"$typeKey" is not a remote-backed master type');
    return remote.create(
      name: name,
      description: description,
      fullForm: fullForm,
      isActive: isActive,
      companyId: companyId,
    );
  }

  @override
  Future<MasterItem> update(
    String typeKey,
    String id, {
    String? name,
    String? description,
    String? fullForm,
    bool? isActive,
  }) {
    final remote = _remoteFor(typeKey);
    if (remote == null) throw StateError('"$typeKey" is not a remote-backed master type');
    return remote.update(id, name: name, description: description, fullForm: fullForm, isActive: isActive);
  }

  @override
  Future<void> delete(String typeKey, String id) {
    final remote = _remoteFor(typeKey);
    if (remote == null) throw StateError('"$typeKey" is not a remote-backed master type');
    return remote.delete(id);
  }
}
