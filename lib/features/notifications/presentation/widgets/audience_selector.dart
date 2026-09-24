import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/search_field.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../companies/presentation/providers/companies_provider.dart';
import '../../domain/entities/audience_target.dart';

/// The one reusable audience-targeting component shared by Push
/// Notifications and Announcements — never duplicated between the two.
/// Estimated recipients are always computed live against the real,
/// already-loaded companies list (`companiesProvider`), never a hardcoded
/// or stale count.
class AudienceSelector extends ConsumerWidget {
  final AudienceTarget value;
  final ValueChanged<AudienceTarget> onChanged;
  const AudienceSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(companiesProvider);

    return companiesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Could not load companies: $e',
          style: TextStyle(color: AppColors.accentRose, fontSize: 12.5),
        ),
      ),
      data: (companies) => _buildBody(context, companies),
    );
  }

  Widget _buildBody(BuildContext context, List<Company> companies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _AudienceOption(
                label: 'All Companies',
                icon: Icons.public_rounded,
                selected: value.type == AudienceType.allCompanies,
                onTap: () => onChanged(const AudienceTarget.allCompanies()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AudienceOption(
                label: 'Selected Companies',
                icon: Icons.checklist_rounded,
                selected: value.type == AudienceType.selectedCompanies,
                onTap: () => onChanged(
                  AudienceTarget.selectedCompanies(value.companyIds),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _AudienceOption(
                label: 'By Subscription Plan',
                icon: Icons.workspace_premium_outlined,
                selected: value.type == AudienceType.byPlan,
                onTap: () {
                  final plans = _distinctPlans(companies);
                  onChanged(
                    AudienceTarget.byPlan(
                      value.plan ?? (plans.isNotEmpty ? plans.first : ''),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AudienceOption(
                label: 'By Company Status',
                icon: Icons.toggle_on_outlined,
                selected: value.type == AudienceType.byStatus,
                onTap: () => onChanged(
                  AudienceTarget.byStatus(activeOnly: value.activeOnly ?? true),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        switch (value.type) {
          AudienceType.allCompanies => _AllCompaniesPanel(
            companies: companies,
            target: value,
          ),
          AudienceType.selectedCompanies => _SelectedCompaniesPanel(
            companies: companies,
            target: value,
            onChanged: onChanged,
          ),
          AudienceType.byPlan => _ByPlanPanel(
            companies: companies,
            target: value,
            onChanged: onChanged,
          ),
          AudienceType.byStatus => _ByStatusPanel(
            companies: companies,
            target: value,
            onChanged: onChanged,
          ),
        },
      ],
    );
  }

  static List<String> _distinctPlans(List<Company> companies) {
    return companies
        .map((c) => c.subscriptionPlan)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  }
}

class _AudienceOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _AudienceOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.1)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? cs.primary : Theme.of(context).dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? cs.primary : cs.onSurface,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: selected
                  ? cs.primary
                  : cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _estimatedRecipients(BuildContext context, int count) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: AppColors.positive.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.groups_rounded, size: 18, color: AppColors.positive),
        const SizedBox(width: 8),
        Text(
          'Estimated Recipients: $count ${count == 1 ? 'company' : 'companies'}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.positive,
          ),
        ),
      ],
    ),
  );
}

class _AllCompaniesPanel extends StatelessWidget {
  final List<Company> companies;
  final AudienceTarget target;
  const _AllCompaniesPanel({required this.companies, required this.target});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All active companies',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        _estimatedRecipients(context, target.estimatedRecipients(companies)),
      ],
    );
  }
}

/// Deliberately collapsed to a compact summary — this used to embed the
/// full company list (search + rows) directly in the form, which meant
/// reaching Priority/Delivery further down meant scrolling past every
/// company first. The full searchable list now lives in its own bottom
/// sheet, opened on demand, so the form itself stays a fixed, short height
/// regardless of how many companies exist.
class _SelectedCompaniesPanel extends StatelessWidget {
  final List<Company> companies;
  final AudienceTarget target;
  final ValueChanged<AudienceTarget> onChanged;
  const _SelectedCompaniesPanel({
    required this.companies,
    required this.target,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedIds = target.companyIds.toSet();
    final selected = companies
        .where((c) => selectedIds.contains(c.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openPicker(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selected.isEmpty
                        ? 'Choose companies'
                        : '${selected.length} ${selected.length == 1 ? 'company' : 'companies'} selected',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selected.isEmpty
                          ? FontWeight.w500
                          : FontWeight.w700,
                      color: selected.isEmpty
                          ? cs.onSurfaceVariant
                          : cs.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selected
                .take(6)
                .map((c) => _CompanyChip(name: c.name))
                .followedBy(
                  selected.length > 6
                      ? [_CompanyChip(name: '+${selected.length - 6} more')]
                      : const [],
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 10),
        _estimatedRecipients(context, target.estimatedRecipients(companies)),
      ],
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CompanyPickerSheet(
        companies: companies,
        initialSelectedIds: target.companyIds,
        onChanged: (ids) => onChanged(AudienceTarget.selectedCompanies(ids)),
      ),
    );
  }
}

class _CompanyChip extends StatelessWidget {
  final String name;
  const _CompanyChip({required this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
      ),
    );
  }
}

/// The full searchable, multi-select company list — a bottom sheet instead
/// of an inline list so it gets real screen height to work with, and a
/// self-contained `State` (unlike the old `StatefulBuilder`, whose search
/// query was computed in the *enclosing* stateless build method and so
/// never actually re-ran when the search text changed).
class _CompanyPickerSheet extends StatefulWidget {
  final List<Company> companies;
  final List<String> initialSelectedIds;
  final ValueChanged<List<String>> onChanged;
  const _CompanyPickerSheet({
    required this.companies,
    required this.initialSelectedIds,
    required this.onChanged,
  });

  @override
  State<_CompanyPickerSheet> createState() => _CompanyPickerSheetState();
}

class _CompanyPickerSheetState extends State<_CompanyPickerSheet> {
  final _searchCtrl = TextEditingController();
  late Set<String> _selectedIds = widget.initialSelectedIds.toSet();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(
      () => _selectedIds.contains(id)
          ? _selectedIds.remove(id)
          : _selectedIds.add(id),
    );
    widget.onChanged(_selectedIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _query.isEmpty
        ? widget.companies
        : widget.companies
              .where((c) => c.name.toLowerCase().contains(_query))
              .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: Row(
                  children: [
                    Text(
                      'Choose Companies',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedIds.length} selected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SearchField(
                  controller: _searchCtrl,
                  hintText: 'Search companies...',
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
                child: Row(
                  children: [
                    _ToolbarPill(
                      label: 'Select All',
                      onTap: () {
                        setState(
                          () => _selectedIds = widget.companies
                              .map((c) => c.id)
                              .toSet(),
                        );
                        widget.onChanged(_selectedIds.toList());
                      },
                    ),
                    const SizedBox(width: 8),
                    _ToolbarPill(
                      label: 'Clear All',
                      onTap: () {
                        setState(() => _selectedIds = {});
                        widget.onChanged(const []);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No companies found'))
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final c = filtered[i];
                          return _CompanyRow(
                            company: c,
                            checked: _selectedIds.contains(c.id),
                            onTap: () => _toggle(c.id),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ByPlanPanel extends StatelessWidget {
  final List<Company> companies;
  final AudienceTarget target;
  final ValueChanged<AudienceTarget> onChanged;
  const _ByPlanPanel({
    required this.companies,
    required this.target,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final plans =
        companies
            .map((c) => c.subscriptionPlan)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plans.isEmpty)
          Text(
            'No companies with a subscription plan yet',
            style: TextStyle(fontSize: 12.5, color: AppColors.textHint),
          )
        else
          BrixenDropdown<String>(
            hint: 'Select Plan',
            value: target.plan,
            items: plans,
            labelOf: (p) => p,
            icon: Icons.workspace_premium_outlined,
            onChanged: (v) =>
                onChanged(AudienceTarget.byPlan(v ?? plans.first)),
          ),
        const SizedBox(height: 10),
        _estimatedRecipients(context, target.estimatedRecipients(companies)),
      ],
    );
  }
}

class _ByStatusPanel extends StatelessWidget {
  final List<Company> companies;
  final AudienceTarget target;
  final ValueChanged<AudienceTarget> onChanged;
  const _ByStatusPanel({
    required this.companies,
    required this.target,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final activeOnly = target.activeOnly ?? true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatusChoiceChip(
                label: 'Active',
                selected: activeOnly,
                onTap: () =>
                    onChanged(AudienceTarget.byStatus(activeOnly: true)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatusChoiceChip(
                label: 'Inactive',
                selected: !activeOnly,
                onTap: () =>
                    onChanged(AudienceTarget.byStatus(activeOnly: false)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _estimatedRecipients(context, target.estimatedRecipients(companies)),
      ],
    );
  }
}

class _StatusChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _StatusChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : Theme.of(context).dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ToolbarPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ToolbarPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}

/// One selectable company row — same visual language as the account
/// switcher's rows (gradient initial avatar, name + meta subtitle, trailing
/// selection indicator) instead of a plain `CheckboxListTile`.
class _CompanyRow extends StatelessWidget {
  final Company company;
  final bool checked;
  final VoidCallback onTap;
  const _CompanyRow({
    required this.company,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = company.name.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: checked
              ? cs.primary.withValues(alpha: 0.08)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: checked
                ? cs.primary.withValues(alpha: 0.4)
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.accentGradient(AppColors.brand),
                ),
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${company.subscriptionPlan ?? '—'} · ${company.isActive ? 'Active' : 'Inactive'}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            Icon(
              checked
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: checked
                  ? cs.primary
                  : cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
