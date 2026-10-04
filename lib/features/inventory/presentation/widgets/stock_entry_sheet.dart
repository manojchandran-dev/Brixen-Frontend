import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/inventory_provider.dart';
import 'inventory_widgets.dart';

/// What the entry sheet records.
enum StockEntryMode { stockIn, stockOut, adjust }

Future<void> showStockEntrySheet(
  BuildContext context, {
  required StockEntryMode mode,
  StockLine? line,
}) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) => StockEntrySheet(mode: mode, line: line),
);

/// Stock In / Stock Out / Adjustment for one product (variant = a product
/// with its size and colour). Purchases and sales move stock on their own
/// — this is for everything else (returns, damage, usage, counts).
class StockEntrySheet extends ConsumerStatefulWidget {
  final StockEntryMode mode;
  final StockLine? line;
  const StockEntrySheet({super.key, required this.mode, this.line});

  @override
  ConsumerState<StockEntrySheet> createState() => _StockEntrySheetState();
}

class _StockEntrySheetState extends ConsumerState<StockEntrySheet> {
  final _qty = TextEditingController();
  final _ref = TextEditingController();
  final _note = TextEditingController();
  StockLine? _line;
  bool _decrease = true; // adjust: − / +
  bool _count = false; // adjust: set to a counted number
  late String _reason;
  bool _saving = false;
  String? _error;

  // Reasons the API accepts, per mode.
  List<String> get _reasons => switch (widget.mode) {
    StockEntryMode.stockIn => const [
      'return',
      'opening',
      'correction',
      'other',
    ],
    StockEntryMode.stockOut => const [
      'other',
      'damage',
      'return',
      'correction',
    ],
    StockEntryMode.adjust => stockReasons,
  };

  @override
  void initState() {
    super.initState();
    _line = widget.line;
    _reason = _reasons.first;
  }

  @override
  void dispose() {
    _qty.dispose();
    _ref.dispose();
    _note.dispose();
    super.dispose();
  }

  String get _title => switch (widget.mode) {
    StockEntryMode.stockIn => 'Stock in',
    StockEntryMode.stockOut => 'Stock out',
    StockEntryMode.adjust => 'Stock adjustment',
  };

  // Stock-out "other" reads as usage (samples, own use…).
  String _reasonText(String r) =>
      widget.mode == StockEntryMode.stockOut && r == 'other'
      ? 'Usage / other'
      : r == 'return' && widget.mode == StockEntryMode.stockOut
      ? 'Return to supplier'
      : r == 'return'
      ? 'Customer return'
      : reasonLabel(r);

  Future<void> _save() async {
    final line = _line;
    final n = int.tryParse(_qty.text.trim());
    if (line == null) return setState(() => _error = 'Choose a product');
    if (n == null || n < 0 || (!_count && n == 0)) {
      return setState(
        () => _error = _count ? 'Enter the counted stock' : 'Enter a quantity',
      );
    }
    final note = [
      if (_ref.text.trim().isNotEmpty) 'Ref: ${_ref.text.trim()}',
      if (_note.text.trim().isNotEmpty) _note.text.trim(),
    ].join(' · ');
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await adjustStock(
        ref,
        productId: line.item.productId,
        change: _count
            ? null
            : switch (widget.mode) {
                StockEntryMode.stockIn => n,
                StockEntryMode.stockOut => -n,
                StockEntryMode.adjust => _decrease ? -n : n,
              },
        setTo: _count ? n : null,
        reason: _reason,
        note: note,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickProduct() async {
    final lines = watchStockLines(ref) ?? const <StockLine>[];
    final picked = await showModalBottomSheet<StockLine>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VariantPicker(lines: lines),
    );
    if (picked != null) setState(() => _line = picked);
  }

  InputDecoration _box(String label, {IconData? icon, String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    final line = _line;
    final accent = switch (mode) {
      StockEntryMode.stockIn => AppColors.positive,
      StockEntryMode.stockOut => AppColors.brand,
      StockEntryMode.adjust => AppColors.brandDeep,
    };
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.9,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.accentGradient(accent),
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(switch (mode) {
                  StockEntryMode.stockIn => Icons.south_west_rounded,
                  StockEntryMode.stockOut => Icons.north_east_rounded,
                  StockEntryMode.adjust => Icons.tune_rounded,
                }, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          // Purchases / sales already move stock — point there first.
          if (mode != StockEntryMode.adjust) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mode == StockEntryMode.stockIn
                          ? 'Bought from a supplier? Record a purchase — it adds stock automatically.'
                          : 'Sold it? Record a sale — it takes stock out automatically.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push(
                        mode == StockEntryMode.stockIn
                            ? AppRouter.createPurchase
                            : AppRouter.createSale,
                      );
                    },
                    child: Text(
                      mode == StockEntryMode.stockIn ? 'Purchase' : 'Sale',
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Product / variant.
          InkWell(
            onTap: widget.line == null ? _pickProduct : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: line == null
                  ? Row(
                      children: [
                        const Icon(
                          Icons.checkroom_rounded,
                          color: AppColors.brand,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Choose product / variant',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.expand_more_rounded,
                          color: AppColors.textHint,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.name,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 5,
                                runSpacing: 4,
                                children: [
                                  if (line.sku.isNotEmpty)
                                    InvChip(Icons.qr_code_rounded, line.sku),
                                  if (line.size.isNotEmpty)
                                    InvChip(
                                      Icons.straighten_rounded,
                                      line.size,
                                    ),
                                  if (line.color.isNotEmpty)
                                    InvChip(Icons.palette_outlined, line.color),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${line.item.quantity}\nin stock',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                        if (widget.line == null)
                          Icon(
                            Icons.expand_more_rounded,
                            color: AppColors.textHint,
                          ),
                      ],
                    ),
            ),
          ),
          if (mode == StockEntryMode.adjust) ...[
            const SizedBox(height: 14),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Increase / decrease')),
                ButtonSegment(value: true, label: Text('Set count')),
              ],
              selected: {_count},
              onSelectionChanged: (v) => setState(() {
                _count = v.first;
                _reason = _count ? 'correction' : _reasons.first;
              }),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (mode == StockEntryMode.adjust && !_count) ...[
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('−')),
                    ButtonSegment(value: false, label: Text('+')),
                  ],
                  selected: {_decrease},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) =>
                      setState(() => _decrease = v.first),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  decoration: _box(
                    _count ? 'Counted stock' : 'Quantity',
                    icon: Icons.numbers_rounded,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date: the backend stamps the time of saving.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Date: today, ${DateFormat('d MMM yyyy').format(DateTime.now())}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('$mode$_count'),
            initialValue: _reason,
            decoration: _box('Reason', icon: Icons.label_outline_rounded),
            items: [
              for (final r in _reasons)
                DropdownMenuItem(value: r, child: Text(_reasonText(r))),
            ],
            onChanged: (v) => setState(() => _reason = v ?? _reason),
          ),
          if (mode != StockEntryMode.adjust) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _ref,
              decoration: _box(
                mode == StockEntryMode.stockIn
                    ? 'Source / reference'
                    : 'Sale / usage reference',
                icon: Icons.tag_rounded,
                hint: mode == StockEntryMode.stockIn
                    ? 'e.g. return from Ravi'
                    : 'e.g. samples to store',
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: _box('Note (optional)', icon: Icons.notes_rounded),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Save ${_title.toLowerCase()}'),
          ),
          if (line != null) ...[
            const SizedBox(height: 22),
            Text(
              'Recent history',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            ref
                .watch(
                  stockMovementsProvider(
                    movementsQuery(productId: line.item.productId),
                  ),
                )
                .when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (e, _) => Text(
                    '$e',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  data: (list) => list.isEmpty
                      ? Text(
                          'No stock changes yet',
                          style: TextStyle(color: AppColors.textHint),
                        )
                      : Column(
                          children: [
                            for (final m in list.take(10))
                              MovementTile(m, showProduct: false),
                          ],
                        ),
                ),
          ],
        ],
      ),
    );
  }
}

/// Searchable list of products (each one a size/colour variant).
class _VariantPicker extends StatefulWidget {
  final List<StockLine> lines;
  const _VariantPicker({required this.lines});

  @override
  State<_VariantPicker> createState() => _VariantPickerState();
}

class _VariantPickerState extends State<_VariantPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final shown = [
      for (final l in widget.lines)
        if (q.isEmpty || l.searchText.contains(q)) l,
    ];
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _q = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => StockLineTile(
                      line: shown[i],
                      onTap: () => Navigator.of(context).pop(shown[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
