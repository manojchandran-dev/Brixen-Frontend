import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/session_service.dart';
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

  static const full = ModuleAccess(view: true, create: true, edit: true, delete: true);
  static const none = ModuleAccess(view: false, create: false, edit: false, delete: false);
}

/// The signed-in company's saved grants, keyed by module id. Employees
/// inherit their company's grants. Empty for superadmin (no restrictions).
final _myGrantsProvider = FutureProvider<Map<String, PermissionModel>>((ref) async {
  ref.watch(authStateProvider);
  final companyId = Session.companyId;
  if (Session.isSuperAdmin || companyId == null) return const {};
  final rows = await ref
      .read(permissionsRepositoryProvider)
      .getPermissions(companyId: companyId);
  return {for (final p in rows) p.moduleId: p};
});

/// Modules a company may use without a saved permission row.
const _allowedWithoutRow = {'support ticket', 'chatbot'};

/// Access for a module by its name as the modules API spells it, e.g.
/// `moduleAccessProvider('Employees')`, `moduleAccessProvider('Units')`.
///
/// Mirrors the backend's rules (it enforces them too, with a 403):
/// every action needs `view` plus its own flag; no saved row = denied,
/// except Support Ticket / Chatbot; Company Category is never writable.
final moduleAccessProvider = Provider.family<ModuleAccess, String>((ref, moduleName) {
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
    return _allowedWithoutRow.contains(name) ? ModuleAccess.full : ModuleAccess.none;
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
