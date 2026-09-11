import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../companies/presentation/providers/companies_provider.dart';
import '../../domain/entities/module_permission.dart';
import '../providers/permissions_provider.dart';

/// List of companies with their module-access summary — same list/create/
/// edit/delete shape as every other module (Products, Employees, ...).
/// Reachable from the drawer's "Permissions" item.
class PermissionManagementPage extends ConsumerStatefulWidget {
  const PermissionManagementPage({super.key});

  @override
  ConsumerState<PermissionManagementPage> createState() =>
      _PermissionManagementPageState();
}

class _PermissionManagementPageState
    extends ConsumerState<PermissionManagementPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: Icon(Icons.menu_rounded, color: AppColors.ink),
          ),
        ),
        title: Text(
          'Permissions',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRouter.createPermission),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.accentGradient(AppColors.brand),
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.add_rounded, size: 20, color: AppColors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.shadows([
                  BoxShadow(
                    color: AppColors.shadowDark.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: AppColors.ink, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search company…',
                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          Expanded(
            child: companiesAsync.when(
              loading: () => const SkeletonListView(),
              error: (e, _) => ErrorCard(
                error: e,
                onRetry: () => ref.invalidate(companiesProvider),
              ),
              data: (companies) {
                final q = _searchCtrl.text.trim().toLowerCase();
                final filtered = q.isEmpty
                    ? companies
                    : companies
                        .where((c) => c.name.toLowerCase().contains(q))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      companies.isEmpty ? 'No companies yet' : 'No results',
                      style: TextStyle(color: AppColors.textHint, fontSize: 14),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _CompanyPermissionCard(company: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyPermissionCard extends ConsumerWidget {
  final Company company;
  const _CompanyPermissionCard({required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsProvider(company.id)).valueOrNull ?? [];
    final fullCount = permissions.where((m) => m.accessLevel == AccessLevel.full).length;
    final customCount = permissions.where((m) => m.accessLevel == AccessLevel.custom).length;
    final noneCount = permissions.where((m) => m.accessLevel == AccessLevel.none).length;

    return SwipeActions(
      onTap: () => context.push(AppRouter.createPermission, extra: company),
      actions: [
        SwipeAction(
          icon: Icons.edit_outlined,
          label: 'Edit',
          color: AppColors.brand,
          onTap: () => context.push(AppRouter.createPermission, extra: company),
        ),
        SwipeAction(
          icon: Icons.restore_outlined,
          label: 'Delete',
          color: AppColors.brandBlack,
          onTap: () => _confirmReset(context, ref),
        ),
      ],
      child: RichCardShell(
        accentColor: AppColors.brand,
        showAccentBar: false,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.accentGradient(AppColors.brand),
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  company.initials,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Owner: ${company.ownerName}',
                      style: const TextStyle(
                        color: AppColors.positive,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _CountChip(count: fullCount, label: 'Full', color: AppColors.positive),
                        const SizedBox(width: 6),
                        _CountChip(count: customCount, label: 'Custom', color: AppColors.brand),
                        const SizedBox(width: 6),
                        _CountChip(count: noneCount, label: 'None', color: AppColors.textHint),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset Permissions', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
        content: Text(
          'Reset "${company.name}" back to full access on every module? This clears any custom restrictions.',
          style: TextStyle(color: AppColors.textHint, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dCtx).pop();
              try {
                await ref.read(permissionsProvider(company.id).notifier).reset();
              } catch (e) {
                if (context.mounted) showErrorDialog(context, e);
              }
            },
            child: const Text('Reset', style: TextStyle(color: AppColors.brandBlack, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _CountChip({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
