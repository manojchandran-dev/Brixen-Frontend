/// One saved `/api/v1/permissions` row — a single (company_id, module_id)
/// grant. `accessLevel` is server-derived from the four booleans, so the
/// client never recomputes it.
class PermissionModel {
  final String id;
  final String companyId;
  final String moduleId;
  final bool view;
  final bool create;
  final bool edit;
  final bool delete;
  final String accessLevel;

  const PermissionModel({
    required this.id,
    required this.companyId,
    required this.moduleId,
    required this.view,
    required this.create,
    required this.edit,
    required this.delete,
    required this.accessLevel,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) =>
      PermissionModel(
        id: json['id'].toString(),
        companyId: (json['company_id'] ?? '').toString(),
        moduleId: (json['module_id'] ?? '').toString(),
        view: json['view'] == true,
        create: json['create'] == true,
        edit: json['edit'] == true,
        delete: json['delete'] == true,
        accessLevel: (json['access_level'] ?? '').toString(),
      );
}
