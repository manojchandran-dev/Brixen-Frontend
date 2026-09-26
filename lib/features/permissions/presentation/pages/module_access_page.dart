import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../domain/entities/module_permission.dart';
import '../providers/permissions_provider.dart';

/// Access-level + granular-permission editor for a single module, scoped
/// to one company. Edits stage locally and only commit to
/// [permissionsProvider] when "Apply Changes" is tapped.
class ModuleAccessPage extends ConsumerStatefulWidget {
  final String companyId;
  final String moduleKey;
  const ModuleAccessPage({
    super.key,
    required this.companyId,
    required this.moduleKey,
  });

  @override
  ConsumerState<ModuleAccessPage> createState() => _ModuleAccessPageState();
}

class _ModuleAccessPageState extends ConsumerState<ModuleAccessPage> {
  // Seeded from the provider on first successful load, then edited locally
  // until "Apply Changes" commits it back — the `??=` in build() means a
  // provider refresh never clobbers in-progress edits.
  ModulePermission? _staged;
  bool _submitting = false;

  void _setLevel(AccessLevel level) {
    setState(() => _staged = _staged!.withAccessLevel(level));
  }

  void _setFlag({bool? view, bool? create, bool? edit, bool? delete}) {
    setState(
      () => _staged = _staged!.copyWith(
        canView: view,
        canCreate: create,
        canEdit: edit,
        canDelete: delete,
      ),
    );
  }

  Future<void> _apply() async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(permissionsProvider(widget.companyId).notifier)
          .saveModule(_staged!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_staged!.name} access updated')),
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
    final permissionsAsync = ref.watch(permissionsProvider(widget.companyId));
    _staged ??= permissionsAsync.valueOrNull?.firstWhere(
      (m) => m.key == widget.moduleKey,
    );

    if (_staged == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          ),
          title: Text(
            'Module Access',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: permissionsAsync.hasError
            ? ErrorCard(
                error: permissionsAsync.error!,
                onRetry: () =>
                    ref.invalidate(permissionsProvider(widget.companyId)),
              )
            : const Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
      );
    }

    final staged = _staged!;
    final locked = staged.accessLevel != AccessLevel.custom;

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
          'Module Access',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _ModuleCard(module: staged),
                const SizedBox(height: 24),
                _SectionLabel('Access Level'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final level in AccessLevel.values) ...[
                      Expanded(
                        child: _AccessLevelCard(
                          level: level,
                          selected: staged.accessLevel == level,
                          onTap: () => _setLevel(level),
                        ),
                      ),
                      if (level != AccessLevel.values.last)
                        const SizedBox(width: 10),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                _SectionLabel('Permissions'),
                const SizedBox(height: 10),
                _PermissionToggle(
                  icon: Icons.visibility_outlined,
                  color: AppColors.brand,
                  title: 'View',
                  subtitle: 'View ${staged.name.toLowerCase()} data',
                  value: staged.canView,
                  enabled: !locked,
                  onChanged: (v) => _setFlag(view: v),
                ),
                const SizedBox(height: 10),
                _PermissionToggle(
                  icon: Icons.add_rounded,
                  color: AppColors.brand,
                  title: 'Create',
                  subtitle: 'Create new ${staged.name.toLowerCase()}',
                  value: staged.canCreate,
                  enabled: !locked,
                  onChanged: (v) => _setFlag(create: v),
                ),
                const SizedBox(height: 10),
                _PermissionToggle(
                  icon: Icons.edit_outlined,
                  color: AppColors.brand,
                  title: 'Edit',
                  subtitle: 'Edit existing ${staged.name.toLowerCase()}',
                  value: staged.canEdit,
                  enabled: !locked,
                  onChanged: (v) => _setFlag(edit: v),
                ),
                const SizedBox(height: 10),
                _PermissionToggle(
                  icon: Icons.delete_outline,
                  color: AppColors.brandBlack,
                  title: 'Delete',
                  subtitle: 'Delete ${staged.name.toLowerCase()}',
                  value: staged.canDelete,
                  enabled: !locked,
                  onChanged: (v) => _setFlag(delete: v),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: BrixenButton(
                label: 'Apply Changes',
                isLoading: _submitting,
                onPressed: _submitting ? null : _apply,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final ModulePermission module;
  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.accentGradient(
            module.color,
          ).map((c) => c.withValues(alpha: 0.12)).toList(),
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: module.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.accentGradient(module.color),
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.shadows([
                BoxShadow(
                  color: module.color.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]),
            ),
            child: Icon(module.icon, size: 26, color: AppColors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.name,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  module.description,
                  style: TextStyle(color: AppColors.textHint, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
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
      style: TextStyle(
        color: AppColors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _AccessLevelCard extends StatelessWidget {
  final AccessLevel level;
  final bool selected;
  final VoidCallback onTap;
  const _AccessLevelCard({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  Color get _color => switch (level) {
    AccessLevel.none => AppColors.textHint,
    AccessLevel.custom => AppColors.brand,
    AccessLevel.full => AppColors.positive,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? _color.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _color : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(level.icon, color: _color, size: 22),
            const SizedBox(height: 8),
            Text(
              level.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionToggle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _PermissionToggle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? (v) => onChanged(v) : null,
            activeTrackColor: AppColors.positive,
            activeThumbColor: AppColors.white,
          ),
        ],
      ),
    );
  }
}
