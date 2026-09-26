import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/permissions_repository.dart';
import '../datasources/permissions_remote_datasource.dart';
import '../models/permission_model.dart';

final permissionsRepositoryProvider = Provider<PermissionsRepository>((ref) {
  return PermissionsRepositoryImpl(
    ref.read(permissionsRemoteDatasourceProvider),
  );
});

class PermissionsRepositoryImpl implements PermissionsRepository {
  final PermissionsRemoteDatasource _ds;
  const PermissionsRepositoryImpl(this._ds);

  @override
  Future<List<PermissionModel>> getPermissions({
    required String companyId,
    String? moduleId,
  }) => _ds.getPermissions(companyId: companyId, moduleId: moduleId);

  @override
  Future<PermissionModel> create({
    required String companyId,
    required String moduleId,
    required bool view,
    required bool create,
    required bool edit,
    required bool delete,
  }) => _ds.create(
    companyId: companyId,
    moduleId: moduleId,
    view: view,
    create: create,
    edit: edit,
    delete: delete,
  );

  @override
  Future<PermissionModel> update(
    String id, {
    required String companyId,
    required bool view,
    required bool create,
    required bool edit,
    required bool delete,
  }) => _ds.update(
    id,
    companyId: companyId,
    view: view,
    create: create,
    edit: edit,
    delete: delete,
  );

  @override
  Future<List<PermissionModel>> bulkUpsert({
    required String companyId,
    required List<Map<String, dynamic>> permissions,
  }) => _ds.bulkUpsert(companyId: companyId, permissions: permissions);

  @override
  Future<void> delete(String id, {required String companyId}) =>
      _ds.delete(id, companyId: companyId);
}
