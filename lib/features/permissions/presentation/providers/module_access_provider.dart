import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/session_service.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../navigation/domain/entities/nav_module.dart';
import '../../../navigation/presentation/providers/nav_modules_provider.dart';
import '../../data/models/permission_model.dart';
import '../../data/repositories/permissions_repository_impl.dart';

/// What the signed-in user may do inside one module — drives which
/// Add / Edit / Delete buttons a screen shows.
class ModuleAccess {
  final bool view, create, edit, delete;
  const ModuleAccess({
    required this.view,
    required this.create,
    required this.edit,
    required this.delete,
  });

  static const full = ModuleAccess(
    view: true,
    create: true,
    edit: true,
    delete: true,
  );
  static const none = ModuleAccess(
    view: false,
    create: false,
    edit: false,
    delete: false,
  );
}

/// The signed-in user's grants, keyed by module id: a company admin's are
/// the company's (set by the superadmin); an employee's are their own grant
/// combined with the company's (set by the company admin, from
/// `/me/permissions`). Empty for superadmin (no restrictions).
final _myGrantsProvider = FutureProvider<Map<String, PermissionModel>>((
  ref,
) async {
  ref.watch(authStateProvider);
  final companyId = Session.companyId;
  if (Session.isSuperAdmin || companyId == null) return const {};
  if (Session.role == UserRole.employee) {
    final resp = await ref.read(dioProvider).get(ApiEndpoints.myPermissions);
    final data = resp.data is Map ? (resp.data['data'] ?? resp.data) : resp.data;
    final items = (data is Map ? data['items'] : data) as List? ?? const [];
    final rows = [
      for (final r in items)
        PermissionModel.fromJson({
          'id': '',
          'company_id': companyId,
          ...(r as Map).cast<String, dynamic>(),
        }),
    ];
    return {for (final p in rows) p.moduleId: p};
  }
  final rows = await ref
      .read(permissionsRepositoryProvider)
      .getPermissions(companyId: companyId);
  return {for (final p in rows) p.moduleId: p};
});

/// Whether [moduleAccessProvider] has what it needs to answer — until then
/// it answers "no access", so a screen can wait instead of showing that.
final moduleAccessReadyProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);
  if (Session.isSuperAdmin) return true;
  return ref.watch(_myGrantsProvider).hasValue &&
      ref.watch(grantableModulesProvider).hasValue;
});

/// Modules a company may use without a saved permission row. Employees
/// only ever get what's granted to them.
const _allowedWithoutRow = {'support ticket', 'chatbot'};

/// Access for a module by its name as the modules API spells it, e.g.
/// `moduleAccessProvider('Employees')`, `moduleAccessProvider('Units')`.
///
/// Mirrors the backend's rules (it enforces them too, with a 403):
/// every action needs `view` plus its own flag; no saved row = denied,
/// except Support Ticket / Chatbot; Company Category is never writable.
final moduleAccessProvider = Provider.family<ModuleAccess, String>((
  ref,
  moduleName,
) {
  ref.watch(authStateProvider);
  if (Session.isSuperAdmin) return ModuleAccess.full;

  final name = moduleName.toLowerCase();
  if (name == 'company category') return ModuleAccess.none;

  final grants = ref.watch(_myGrantsProvider).valueOrNull;
  final tree = ref.watch(grantableModulesProvider).valueOrNull;
  // Until both load, show no actions rather than flash buttons that vanish.
  if (grants == null || tree == null) return ModuleAccess.none;

  final id = _findId(tree, name);
  final g = id == null ? null : grants[id];
  if (g == null) {
    return _allowedWithoutRow.contains(name) &&
            Session.role != UserRole.employee
        ? ModuleAccess.full
        : ModuleAccess.none;
  }
  return ModuleAccess(
    view: g.view,
    create: g.view && g.create,
    edit: g.view && g.edit,
    delete: g.view && g.delete,
  );
});

String? _findId(List<NavModule> modules, String name) {
  for (final m in modules) {
    if (m.name.toLowerCase() == name) return m.id;
    final hit = _findId(m.children, name);
    if (hit != null) return hit;
  }
  return null;
}
