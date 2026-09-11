import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../features/companies/domain/entities/company.dart';
import '../../features/companies/presentation/providers/companies_provider.dart';
import '../providers/super_admin_company_filter_provider.dart';

/// "Browse as company X" filter, shown directly below a list screen's
/// search field — superAdmin only (a companyAdmin/employee session already
/// belongs to one company, so this has nothing to offer them). Selecting a
/// company here feeds [superAdminCompanyFilterProvider], which
/// [CompanyScopeInterceptor] reads to attach `company_id` to every request;
/// each list's own provider watches the same filter, so the list refetches
/// the moment the selection changes.
class SuperAdminCompanyFilterBar extends ConsumerWidget {
  const SuperAdminCompanyFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Session.isSuperAdmin) return const SizedBox.shrink();

    final selected = ref.watch(superAdminCompanyFilterProvider);
    final isActive = selected != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: () => _openPicker(context, ref),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isActive ? AppColors.brand.withValues(alpha: 0.5) : AppColors.border),
            boxShadow: AppColors.shadows([
              BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ]),
          ),
          child: Row(
            children: [
              Icon(Icons.apartment_rounded, size: 18, color: isActive ? AppColors.brand : AppColors.textHint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected?.name ?? 'All Companies',
                  style: TextStyle(
                    color: isActive ? AppColors.ink : AppColors.textHint,
                    fontSize: 13.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive)
                GestureDetector(
                  onTap: () => ref.read(superAdminCompanyFilterProvider.notifier).state = null,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.textHint),
                  ),
                ),
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded, size: 20, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  void _openPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (ctx, sheetRef, _) {
          final companies = sheetRef.watch(companiesProvider).valueOrNull ?? const <Company>[];
          final selected = sheetRef.watch(superAdminCompanyFilterProvider);
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, controller) => Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Row(
                      children: [
                        Text('Filter by Company', style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      children: [
                        _CompanyTile(
                          name: 'All Companies',
                          selected: selected == null,
                          onTap: () {
                            ref.read(superAdminCompanyFilterProvider.notifier).state = null;
                            Navigator.of(ctx).pop();
                          },
                        ),
                        for (final c in companies)
                          _CompanyTile(
                            name: c.name,
                            selected: selected?.id == c.id,
                            onTap: () {
                              ref.read(superAdminCompanyFilterProvider.notifier).state = c;
                              Navigator.of(ctx).pop();
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;
  const _CompanyTile({required this.name, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: selected ? AppColors.brand : AppColors.ink,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_rounded, size: 18, color: AppColors.brand),
          ],
        ),
      ),
    );
  }
}
