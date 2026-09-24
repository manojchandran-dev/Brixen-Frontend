import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../../shared/widgets/company_selector_field.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../companies/domain/entities/company.dart';
import '../../domain/entities/master_item.dart';
import '../../domain/entities/master_type.dart';
import '../cubit/master_cubit.dart';
import '../cubit/master_state.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';

/// Public **duplicate** of `companies_page.dart`'s private master-type list/
/// create/edit widgets — kept as a copy (not an extraction) so the original,
/// proven-working Companies → Menu → Masters drill-down stays completely
/// untouched, following the same precedent as `shared/widgets/app_menu_body.dart`.
/// Used by [MasterCategoryPage] to give each master type its own directly
/// linkable route in parallel with the existing in-page navigation.

// Individual item cards within a master list cycle through the full 5-color
// brand palette by index (same pattern as the Companies list) instead of all
// sharing one flat color per master type.
List<Color> get masterCardAccentColors => [
  AppColors.brand,
  AppColors.positive,
  AppColors.brandDeep,
  AppColors.brandLight,
  AppColors.brandBlack,
];

class MasterItemsBody extends ConsumerStatefulWidget {
  final String typeKey;
  final void Function(String id) onEdit;
  final String? filterCategoryId; // null = show all
  const MasterItemsBody({
    super.key,
    required this.typeKey,
    required this.onEdit,
    this.filterCategoryId,
  });
  @override
  ConsumerState<MasterItemsBody> createState() => _MasterItemsBodyState();
}

class _MasterItemsBodyState extends ConsumerState<MasterItemsBody> {
  final _searchCtrl = TextEditingController();
  String? _selectedCategory; // null = All

  bool get _hasCategories =>
      masterTypeFor(widget.typeKey)?.hasParentAssignment ?? false;

  @override
  void initState() {
    super.initState();
    masterCubit.load(widget.typeKey);
  }

  @override
  void didUpdateWidget(covariant MasterItemsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No Key on this widget, so Flutter reuses this State when navigating
    // between different master types in the same slot — initState won't
    // re-run, so reload explicitly when the type actually changes.
    if (oldWidget.typeKey != widget.typeKey ||
        oldWidget.filterCategoryId != widget.filterCategoryId) {
      masterCubit.load(widget.typeKey);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(moduleAccessProvider(masterModuleName(widget.typeKey)));
    final cs = Theme.of(context).colorScheme;
    final typeCfg = masterTypeFor(widget.typeKey);
    return BlocBuilder<MasterCubit, MasterState>(
      bloc: masterCubit,
      builder: (context, state) {
        if (state is MasterError) {
          return Center(
            child: Text(
              state.message,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          );
        }
        if (state is! MasterLoaded) {
          return const SkeletonListView(
            padding: EdgeInsets.fromLTRB(14, 70, 14, 100),
          );
        }

        // Build unique category list from all items (not just filtered)
        final allItems = state.items;
        final categoryMap = <String, String>{}; // id → name
        for (final item in allItems) {
          if (item.assignedCategoryId != null &&
              item.assignedCategoryName != null) {
            categoryMap[item.assignedCategoryId!] = item.assignedCategoryName!;
          }
        }

        // Apply category filter: prop-level filter takes priority over chip selection
        final items = state.filtered.where((item) {
          final catFilter = widget.filterCategoryId ?? _selectedCategory;
          if (catFilter == null) return true;
          return item.assignedCategoryId == catFilter;
        }).toList();

        // Count per category (for badge)
        final countMap = <String, int>{};
        for (final item in state.items) {
          if (item.assignedCategoryId != null) {
            countMap[item.assignedCategoryId!] =
                (countMap[item.assignedCategoryId!] ?? 0) + 1;
          }
        }

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
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
                    BoxShadow(
                      color: AppColors.highlightShadow(0.85),
                      blurRadius: 6,
                      offset: const Offset(-3, -3),
                    ),
                  ]),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(color: AppColors.ink, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search ${typeCfg?.name ?? 'items'}...',
                    hintStyle: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onChanged: masterCubit.search,
                ),
              ),
            ),

            // Category filter chips (only for assignable types)
            if (_hasCategories && categoryMap.isNotEmpty)
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    MasterFilterChip(
                      label: 'All',
                      count: allItems.length,
                      selected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    ...categoryMap.entries.map(
                      (e) => MasterFilterChip(
                        label: e.value,
                        count: countMap[e.key] ?? 0,
                        selected: _selectedCategory == e.key,
                        onTap: () => setState(() => _selectedCategory = e.key),
                      ),
                    ),
                  ],
                ),
              ),

            if (_hasCategories && categoryMap.isNotEmpty)
              const SizedBox(height: 4),

            // List
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'No items found',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final itemColor =
                            masterCardAccentColors[i %
                                masterCardAccentColors.length];
                        return MasterCard(
                          item: items[i],
                          icon: typeCfg?.icon ?? Icons.list_alt_outlined,
                          color: itemColor,
                          onView: () => showMasterDetail(
                            context,
                            items[i],
                            typeCfg?.icon ?? Icons.list_alt_outlined,
                            itemColor,
                          ),
                          onEdit: !access.edit
                              ? null
                              : () => widget.onEdit(items[i].id),
                          onDelete: !access.delete ? null : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: Theme.of(
                                  ctx,
                                ).colorScheme.surfaceContainerHighest,
                                title: Text(
                                  'Delete ${typeCfg?.name ?? 'item'}?',
                                  style: TextStyle(
                                    color: Theme.of(ctx).colorScheme.onSurface,
                                  ),
                                ),
                                content: Text(
                                  'This will permanently delete "${items[i].name}". This action cannot be undone.',
                                  style: TextStyle(
                                    color: Theme.of(
                                      ctx,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Theme.of(
                                          ctx,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true || !context.mounted) return;
                            masterCubit.delete(items[i].id).then((err) {
                              if (err != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(err),
                                    backgroundColor: AppColors.dangerFill,
                                  ),
                                );
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class MasterFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const MasterFilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.silver.withValues(alpha: 0.18)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.silver : Theme.of(context).dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.silver : cs.onSurfaceVariant,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.silver.withValues(alpha: 0.25)
                    : Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? AppColors.silver : cs.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showMasterDetail(
  BuildContext context,
  MasterItem item,
  IconData icon,
  Color color,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => GestureDetector(
      onTap: () => Navigator.of(ctx).pop(),
      behavior: HitTestBehavior.opaque,
      child: MasterDetailSheet(item: item, icon: icon, color: color),
    ),
  );
}

class MasterDetailSheet extends StatelessWidget {
  final MasterItem item;
  final IconData icon;
  final Color color;
  const MasterDetailSheet({
    super.key,
    required this.item,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final details = <MapEntry<String, String>>[
      if (item.fullForm != null && item.fullForm!.isNotEmpty)
        MapEntry('Full Form', item.fullForm!),
      if (item.assignedCategoryName != null)
        MapEntry('Category', item.assignedCategoryName!),
      if (item.description != null && item.description!.isNotEmpty)
        MapEntry('Description', item.description!),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, controller) => GestureDetector(
        onTap:
            () {}, // absorb taps so the outer dismiss handler ignores sheet touches
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              Expanded(
                child: details.isEmpty
                    ? Center(
                        child: Text(
                          'No additional details',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      )
                    : ListView(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        children: details
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.key.toUpperCase(),
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      e.value,
                                      style: TextStyle(
                                        color: cs.onSurface,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MasterCard extends StatelessWidget {
  final MasterItem item;
  final IconData icon;
  final Color color;
  final VoidCallback onView;
  // null hides that swipe action (no access).
  final VoidCallback? onEdit, onDelete;
  const MasterCard({
    super.key,
    required this.item,
    required this.icon,
    required this.color,
    required this.onView,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Color.lerp(
      AppColors.surface,
      color,
      AppColors.cardTintBlend(color),
    )!;
    final fgMuted = AppColors.ink.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SwipeActions(
        onTap: onView,
        actions: [
          if (onEdit != null)
            SwipeAction(
              icon: Icons.edit_outlined,
              label: 'Edit',
              color: AppColors.brand,
              onTap: onEdit!,
            ),
          if (onDelete != null)
            SwipeAction(
              icon: Icons.delete_outline,
              label: 'Delete',
              color: AppColors.brandBlack,
              onTap: onDelete!,
            ),
        ],
        child: RichCardShell(
          accentColor: color,
          backgroundColor: bg,
          backgroundGradient: AppColors.cardTintGradient(color),
          showAccentBar: false,
          edgeColor: color,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.accentGradient(color),
                    ),
                    shape: BoxShape.circle,
                    boxShadow: AppColors.shadows([
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.fullForm != null && item.fullForm!.isNotEmpty)
                        Text(
                          item.fullForm!,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (item.assignedCategoryName != null)
                        Row(
                          children: [
                            Icon(
                              Icons.category_rounded,
                              size: 11,
                              color: color,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              item.assignedCategoryName!,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      if (item.description != null)
                        Text(
                          item.description!,
                          style: TextStyle(color: fgMuted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: fgMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MasterFormBody extends StatefulWidget {
  final String typeKey;
  final String? editId;
  final String?
  defaultCategoryId; // pre-fill category when creating from drill-down
  final VoidCallback onSaved;
  const MasterFormBody({
    super.key,
    required this.typeKey,
    this.editId,
    this.defaultCategoryId,
    required this.onSaved,
  });
  @override
  State<MasterFormBody> createState() => _MasterFormBodyState();
}

class _MasterFormBodyState extends State<MasterFormBody> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _fullFormCtrl = TextEditingController(); // Unit type only
  bool _isActive = true;
  bool _saving = false;
  bool _loadingItem = false;
  String? _loadError;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  Company? _selectedCompany; // superAdmin only — companyAdmin/employee use Session.companyId

  bool get _isEdit => widget.editId != null;
  bool get _needsCategory =>
      masterTypeFor(widget.typeKey)?.hasParentAssignment ?? false;
  bool get _isRemote => masterCubit.isRemote(widget.typeKey);
  bool get _isUnit => widget.typeKey == 'unit';

  @override
  void initState() {
    super.initState();
    masterCubit.itemsOfType('companyCategory');
    if (_isEdit) {
      if (_isRemote) {
        _loadItemFromApi();
      } else {
        final state = masterCubit.state;
        if (state is MasterLoaded) {
          try {
            _fillFrom(state.items.firstWhere((c) => c.id == widget.editId));
          } catch (_) {}
        }
      }
    } else if (widget.defaultCategoryId != null) {
      // Pre-fill category when navigating from drill-down
      _selectedCategoryId = widget.defaultCategoryId;
      final cats = masterCubit.itemsOfType('companyCategory');
      try {
        _selectedCategoryName = cats
            .firstWhere((c) => c.id == widget.defaultCategoryId)
            .name;
      } catch (_) {}
    }
  }

  void _fillFrom(MasterItem item) {
    _nameCtrl.text = item.name;
    _descCtrl.text = item.description ?? '';
    _fullFormCtrl.text = item.fullForm ?? '';
    _isActive = item.isActive;
    _selectedCategoryId = item.assignedCategoryId;
    _selectedCategoryName = item.assignedCategoryName;
  }

  Future<void> _loadItemFromApi() async {
    setState(() => _loadingItem = true);
    try {
      final item = await masterCubit.fetchByIdRemote(widget.typeKey, widget.editId!);
      if (!mounted) return;
      setState(() => _fillFrom(item));
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingItem = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _fullFormCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_needsCategory && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a company category')),
      );
      return;
    }
    if (!_isEdit && Session.isSuperAdmin && _selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a company'), backgroundColor: AppColors.dangerFill),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final state = masterCubit.state as MasterLoaded;
        final existing = state.items.firstWhere((c) => c.id == widget.editId!);
        await masterCubit.update(
          existing.copyWith(
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            isActive: _isActive,
            assignedCategoryId: _selectedCategoryId,
            assignedCategoryName: _selectedCategoryName,
            fullForm: _isUnit && _fullFormCtrl.text.trim().isNotEmpty
                ? _fullFormCtrl.text.trim()
                : null,
          ),
        );
      } else {
        await masterCubit.add(
          MasterItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            typeKey: widget.typeKey,
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            isActive: _isActive,
            createdAt: DateTime.now(),
            fullForm: _isUnit && _fullFormCtrl.text.trim().isNotEmpty
                ? _fullFormCtrl.text.trim()
                : null,
            assignedCategoryId: _selectedCategoryId,
            assignedCategoryName: _selectedCategoryName,
          ),
          companyId: (Session.isSuperAdmin ? _selectedCompany!.id : Session.companyId)!,
        );
      }
      if (mounted) widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.dangerFill,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typeCfg = masterTypeFor(widget.typeKey);
    final categories = masterCubit.itemsOfType('companyCategory');

    if (_loadingItem) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.silver),
      );
    }
    if (_loadError != null) {
      return Center(
        child: Text(_loadError!, style: TextStyle(color: cs.onSurfaceVariant)),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              children: [
                if (!_isEdit && Session.isSuperAdmin) ...[
                  CompanySelectorField(
                    value: _selectedCompany,
                    onChanged: (c) => setState(() => _selectedCompany = c),
                  ),
                  const SizedBox(height: 18),
                ],
                if (_isUnit) ...[
                  BrixenTextField(
                    label: 'Unit *',
                    hint: 'e.g. pcs',
                    controller: _nameCtrl,
                    prefixIcon: const Icon(Icons.straighten_rounded),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 18),
                  BrixenTextField(
                    label: 'Full Form',
                    hint: 'e.g. Pieces',
                    controller: _fullFormCtrl,
                    prefixIcon: const Icon(Icons.text_fields_rounded),
                  ),
                  const SizedBox(height: 18),
                  BrixenTextField(
                    label: 'Description',
                    hint: 'e.g. Number of garments',
                    controller: _descCtrl,
                    prefixIcon: const Icon(Icons.notes_rounded),
                    maxLines: 3,
                  ),
                ] else ...[
                  BrixenTextField(
                    label: '${typeCfg?.name ?? 'Item'} Name *',
                    hint: 'Enter name',
                    controller: _nameCtrl,
                    prefixIcon: Icon(typeCfg?.icon ?? Icons.list_alt_rounded),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 18),
                  if (_needsCategory) ...[
                    MasterCategoryDropdown(
                      categories: categories,
                      selectedId: _selectedCategoryId,
                      onChanged: (id, name) => setState(() {
                        _selectedCategoryId = id;
                        _selectedCategoryName = name;
                      }),
                    ),
                    const SizedBox(height: 18),
                  ],
                  BrixenTextField(
                    label: 'Description',
                    hint: 'Optional description',
                    controller: _descCtrl,
                    prefixIcon: const Icon(Icons.notes_rounded),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: BrixenButton(
            label: _isEdit
                ? 'Save Changes'
                : 'Create ${typeCfg?.name ?? 'Item'}',
            onPressed: _saving ? null : _save,
            isLoading: _saving,
          ),
        ),
      ],
    );
  }
}

class MasterCategoryDropdown extends StatelessWidget {
  final List<MasterItem> categories;
  final String? selectedId;
  final void Function(String id, String name) onChanged;

  const MasterCategoryDropdown({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedId != null
        ? categories.where((c) => c.id == selectedId).firstOrNull
        : null;

    return BrixenDropdown<MasterItem>(
      hint: 'Assign to Company Category *',
      value: selected,
      items: categories,
      labelOf: (c) => c.name,
      icon: Icons.category_outlined,
      onChanged: (item) {
        if (item == null) return;
        onChanged(item.id, item.name);
      },
    );
  }
}
