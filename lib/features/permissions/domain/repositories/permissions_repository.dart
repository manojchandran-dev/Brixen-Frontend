import '../../data/models/permission_model.dart';

/// Deliberately typed in [PermissionModel] rather than a new domain entity —
/// there is no plain "Permission" entity in this app (the richer
/// [ModulePermission] entity is assembled in the Notifier from a
/// [PermissionModel] plus the module tree). Inventing one here purely for
/// layering purity would be an entity nothing else would ever consume.
abstract class PermissionsRepository {
  Future<List<PermissionModel>> getPermissions({
    required String companyId,
    String? moduleId,
  });
  Future<PermissionModel> create({
    required String companyId,
    required String moduleId,
    required bool view,
    required bool create,
    required bool edit,
    required bool delete,
  });
  Future<PermissionModel> update(
    String id, {
    required String companyId,
    required bool view,
    required bool create,
    required bool edit,
    required bool delete,
  });
  Future<List<PermissionModel>> bulkUpsert({
    required String companyId,
    required List<Map<String, dynamic>> permissions,
  });
  Future<void> delete(String id, {required String companyId});
}
