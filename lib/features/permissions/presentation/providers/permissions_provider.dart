import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../companies/presentation/providers/companies_provider.dart';
import '../../../navigation/domain/entities/nav_module.dart';
import '../../../navigation/presentation/module_visuals.dart';
import '../../../navigation/presentation/providers/nav_modules_provider.dart';
import '../../data/models/permission_model.dart';
import '../../data/repositories/permissions_repository_impl.dart';
import '../../domain/entities/module_permission.dart';

/// Per-company module permissions for the company owner, keyed by company
/// id. The module list comes from `GET /api/v1/modules?for=permissions`
/// (everything a company can be given); saved access grants come from
/// `GET /api/v1/permissions?company_id=...`. A module with no saved row
/// yet is denied (No Access), except Support Ticket / Chatbot — matches
/// the server.
final permissionsProvider =
    AsyncNotifierProvider.family<
      PermissionsNotifier,
      List<ModulePermission>,
      String
    >(PermissionsNotifier.new);

class PermissionsNotifier
    extends FamilyAsyncNotifier<List<ModulePermission>, String> {
  @override
  Future<List<ModulePermission>> build(String arg) async {
    final tree = await ref.watch(grantableModulesProvider.future);
    final saved = await ref
        .read(permissionsRepositoryProvider)
        .getPermissions(companyId: arg);
    final byModuleId = {for (final p in saved) p.moduleId: p};
    return _buildRows(tree, byModuleId);
  }

  // A top-level module with no children becomes a "Modules" row; a
  // top-level module WITH children (e.g. "Masters") becomes a group whose
  // own children are the rows, grouped under its name.
  List<ModulePermission> _buildRows(
    List<NavModule> tree,
    Map<String, PermissionModel> saved,
  ) {
    final rows = <ModulePermission>[];
    for (final m in tree) {
      if (m.children.isEmpty) {
        rows.add(_toRow(m, group: 'Modules', saved: saved[m.id]));
      } else {
        for (final child in m.children) {
          rows.add(_toRow(child, group: m.name, saved: saved[child.id]));
        }
      }
    }
    return rows;
  }

  ModulePermission _toRow(
    NavModule m, {
    required String group,
    PermissionModel? saved,
  }) {
    final visual = moduleVisualFor(m.name);
    if (saved == null) {
      // Backend: no saved row = denied, except Support Ticket / Chatbot.
      final row = ModulePermission.full(
        key: m.id,
        name: m.name,
        description: m.description ?? '',
        icon: visual.icon,
        color: visual.color,
        group: group,
      );
      const allowedWithoutRow = {'support ticket', 'chatbot'};
      return allowedWithoutRow.contains(m.name.toLowerCase())
          ? row
          : row.withAccessLevel(AccessLevel.none);
    }
    return ModulePermission(
      key: m.id,
      name: m.name,
      description: m.description ?? '',
      icon: visual.icon,
      color: visual.color,
      group: group,
      remoteId: saved.id,
      accessLevel: _levelOf(saved),
      canView: saved.view,
      canCreate: saved.create,
      canEdit: saved.edit,
      canDelete: saved.delete,
    );
  }

  /// Persists one module's access — creates the row the first time
  /// (no [ModulePermission.remoteId] yet), updates it after.
  Future<void> saveModule(ModulePermission updated) async {
    final ds = ref.read(permissionsRepositoryProvider);
    final saved = updated.remoteId == null
        ? await ds.create(
            companyId: arg,
            moduleId: updated.key,
            view: updated.canView,
            create: updated.canCreate,
            edit: updated.canEdit,
            delete: updated.canDelete,
          )
        : await ds.update(
            updated.remoteId!,
            companyId: arg,
            view: updated.canView,
            create: updated.canCreate,
            edit: updated.canEdit,
            delete: updated.canDelete,
          );
    final merged = updated.copyWith(
      remoteId: saved.id,
      accessLevel: _levelOf(saved),
    );
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([
      for (final m in current) m.key == merged.key ? merged : m,
    ]);
    // Refresh the Permissions list's Full/Custom/None counts.
    ref.invalidate(permissionCompaniesProvider);
  }

  /// Persists every module currently shown for this company in one bulk
  /// request — the "Create/Save Permissions" button on the whole-list
  /// screen. Turns any still-implicit (no [ModulePermission.remoteId])
  /// modules into real saved rows too, not just the ones individually
  /// edited via [saveModule]. Safe to resubmit: upserted, not duplicated.
  Future<void> bulkSave() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final results = await ref
        .read(permissionsRepositoryProvider)
        .bulkUpsert(
          companyId: arg,
          permissions: [
            for (final m in current)
              {
                'module_id': m.key,
                'view': m.canView,
                'create': m.canCreate,
                'edit': m.canEdit,
                'delete': m.canDelete,
              },
          ],
        );
    final byModuleId = {for (final r in results) r.moduleId: r};
    state = AsyncData([
      for (final m in current)
        if (byModuleId[m.key] case final saved?)
          m.copyWith(remoteId: saved.id, accessLevel: _levelOf(saved))
        else
          m,
    ]);
    // Refresh the Permissions list's Full/Custom/None counts.
    ref.invalidate(permissionCompaniesProvider);
  }

  /// "Delete" — removes every saved override for this company, so every
  /// module falls back to the server default: No Access (Support Ticket and
  /// Chatbot stay allowed).
  Future<void> reset() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final ds = ref.read(permissionsRepositoryProvider);
    for (final m in current) {
      if (m.remoteId != null) {
        await ds.delete(m.remoteId!, companyId: arg);
      }
    }
    ref.invalidateSelf();
    ref.invalidate(permissionCompaniesProvider);
    await future;
  }
}

/// Derived from the four flags rather than the server's `access_level`
/// text, so a wording change there can't mislabel a module.
AccessLevel _levelOf(PermissionModel p) {
  final flags = [p.view, p.create, p.edit, p.delete];
  if (flags.every((f) => f)) return AccessLevel.full;
  if (flags.every((f) => !f)) return AccessLevel.none;
  return AccessLevel.custom;
}
