import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../companies/presentation/providers/companies_provider.dart';
import '../../domain/entities/module_permission.dart';
import '../providers/permissions_provider.dart';

/// Create/edit a company's module permissions — same page shape as every
/// other module's create/edit form, with the company picked from a real
/// dropdown field instead of a tap-to-open sheet.
class CreatePermissionPage extends ConsumerStatefulWidget {
  final Company? company;
  const CreatePermissionPage({super.key, this.company});

  @override
  ConsumerState<CreatePermissionPage> createState() => _CreatePermissionPageState();
}

class _CreatePermissionPageState extends ConsumerState<CreatePermissionPage> {
  Company? _selected;
  bool _submitting = false;

  bool get _isEditing => widget.company != null;

  @override
  void initState() {
    super.initState();
    _selected = widget.company;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(permissionsProvider(_selected!.id).notifier).bulkSave();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permissions saved for ${_selected!.name}')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showErrorDialog(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companies = ref.watch(companiesProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Icon(Icons.arrow_back_rounded, color: AppColors.ink),
        ),
        title: Text(
          _isEditing ? 'Edit Permissions' : 'New Permissions',
          style: TextStyle(color: AppColors.ink, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Text(
            'Company',
            style: TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Opacity(
            opacity: _isEditing ? 0.6 : 1,
            child: IgnorePointer(
              ignoring: _isEditing,
              child: BrixenDropdown<Company>(
                hint: companies.isEmpty ? 'No companies yet' : 'Select company',
                value: _selected,
                items: companies,
                labelOf: (c) => '${c.name} — ${c.ownerName}',
                icon: Icons.business_rounded,
                onChanged: (c) => setState(() => _selected = c),
              ),
            ),
          ),
          if (_selected != null) ...[
            const SizedBox(height: 8),
            Text(
              'Owner: ${_selected!.ownerName}',
              style: const TextStyle(color: AppColors.positive, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 26),
          if (_selected == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Select a company to configure its module permissions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textHint, fontSize: 13),
                ),
              ),
            )
          else
            _PermissionEditor(companyId: _selected!.id),
        ],
      ),
      bottomNavigationBar: _selected == null
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: BrixenButton(
                  label: _isEditing ? 'Save Changes' : 'Create Permissions',
                  isLoading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ),
            ),
    );
  }
}

class _PermissionEditor extends ConsumerWidget {
  final String companyId;
  const _PermissionEditor({required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(permissionsProvider(companyId));

    return permissionsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.brand)),
      ),
      error: (e, _) => ErrorCard(
        error: e,
        onRetry: () => ref.invalidate(permissionsProvider(companyId)),
      ),
      data: (all) {
        // Grouped in whatever order the modules API returns — "Modules"
        // for top-level entries, or the parent's own name (e.g. "Masters")
        // for nested ones. No hardcoded module list on this screen.
        final groups = <String, List<ModulePermission>>{};
        for (final m in all) {
          groups.putIfAbsent(m.group, () => []).add(m);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in groups.entries) ...[
              _SectionLabel(entry.key),
              const SizedBox(height: 10),
              for (final m in entry.value) ...[
                _PermissionRow(companyId: companyId, module: m),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(color: AppColors.textHint, fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.3),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String companyId;
  final ModulePermission module;
  const _PermissionRow({required this.companyId, required this.module});

  Color get _levelColor => switch (module.accessLevel) {
    AccessLevel.full => AppColors.positive,
    AccessLevel.custom => AppColors.brand,
    AccessLevel.none => AppColors.textHint,
  };

  @override
  Widget build(BuildContext context) {
    final flags = [module.canView, module.canCreate, module.canEdit, module.canDelete];

    return RichCardShell(
      accentColor: module.color,
      showAccentBar: false,
      onTap: () => context.push(
        AppRouter.moduleAccess,
        extra: {'companyId': companyId, 'moduleKey': module.key},
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: AppColors.accentGradient(module.color)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(module.icon, size: 18, color: AppColors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.name,
                    style: TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final on in flags)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: on ? AppColors.positive : Colors.transparent,
                            border: on ? null : Border.all(color: AppColors.border, width: 1.2),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _levelColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                module.summary,
                style: TextStyle(color: _levelColor, fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
