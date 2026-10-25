import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/pill_segmented_control.dart';
import '../../domain/entities/product.dart';

// The product form's sizes & colours: pick sizes (quick sets or your own)
// and colours, and every combination becomes a variant with its own prices,
// code and opening stock.

/// Quick size sets offered as chips.
const kSizeSets = <String, List<String>>{
  'Letter': ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'],
  'Waist': ['26', '28', '30', '32', '34', '36', '38', '40', '42', '44'],
  'Kids': [
    '0-1Y',
    '1-2Y',
    '2-3Y',
    '3-4Y',
    '4-6Y',
    '6-8Y',
    '8-10Y',
    '10-12Y',
    '12-14Y',
  ],
  'Other': ['Free size'],
};

/// Colours offered as one-tap chips (any colour can be typed too).
const kCommonColours = [
  'Black',
  'White',
  'Navy',
  'Blue',
  'Grey',
  'Maroon',
  'Red',
  'Green',
  'Yellow',
  'Pink',
  'Beige',
];

String _key(String? size, String? colour) =>
    '${(size ?? '').trim().toLowerCase()}|${(colour ?? '').trim().toLowerCase()}';

/// One variant row being edited in the form.
class VariantDraft {
  /// Set for a variant that's already saved.
  final String? id;
  final String? size;
  final String? colour;

  /// Stock of a saved variant (read-only here; changed through Inventory).
  final int savedStock;
  final retail = TextEditingController();
  final wholesale = TextEditingController();
  final cost = TextEditingController();
  final sku = TextEditingController();
  final openingStock = TextEditingController();

  VariantDraft({this.id, this.size, this.colour, this.savedStock = 0});

  factory VariantDraft.fromVariant(ProductVariant v) {
    String text(double? p) =>
        p == null ? '' : (p % 1 == 0 ? p.toStringAsFixed(0) : '$p');
    final d = VariantDraft(
      id: v.id,
      size: v.size,
      colour: v.color,
      savedStock: v.stockQuantity,
    );
    d.retail.text = text(v.retailPrice);
    d.wholesale.text = text(v.wholesalePrice);
    d.cost.text = text(v.costPrice);
    d.sku.text = v.sku ?? '';
    return d;
  }

  String get key => _key(size, colour);
  String get label =>
      [size, colour].where((s) => s != null && s.isNotEmpty).join(' / ');

  /// Empty price = the product's default.
  ProductVariant toVariant() {
    double? p(TextEditingController c) => double.tryParse(c.text.trim());
    return ProductVariant(
      id: id,
      size: size,
      color: colour,
      sku: sku.text.trim().isEmpty ? null : sku.text.trim(),
      retailPrice: p(retail),
      wholesalePrice: p(wholesale),
      costPrice: p(cost),
      openingStock: int.tryParse(openingStock.text.trim()) ?? 0,
    );
  }

  void clearPrices() {
    retail.clear();
    wholesale.clear();
    cost.clear();
  }

  void dispose() {
    retail.dispose();
    wholesale.dispose();
    cost.dispose();
    sku.dispose();
    openingStock.dispose();
  }
}

/// Keeps one [VariantDraft] per size × colour combination, in order,
/// re-using drafts (and what was typed in them) when the selection changes.
class VariantDrafts {
  final List<String> sizes = [];
  final List<String> colours = [];
  final Map<String, VariantDraft> _byKey = {};

  /// From a saved product: its sizes/colours (first-seen order) and drafts.
  void load(List<ProductVariant> variants) {
    for (final v in variants) {
      final s = v.size?.trim();
      final c = v.color?.trim();
      if (s != null && s.isNotEmpty && !sizes.contains(s)) sizes.add(s);
      if (c != null && c.isNotEmpty && !colours.contains(c)) colours.add(c);
      final d = VariantDraft.fromVariant(v);
      _byKey[d.key] = d;
    }
  }

  /// Every combination of the picked sizes and colours (sizes alone or
  /// colours alone when only one kind is picked).
  List<VariantDraft> get rows {
    final out = <VariantDraft>[];
    final ss = sizes.isEmpty ? <String?>[null] : sizes;
    final cs = colours.isEmpty ? <String?>[null] : colours;
    for (final s in ss) {
      for (final c in cs) {
        if (s == null && c == null) continue;
        out.add(
          _byKey.putIfAbsent(
            _key(s, c),
            () => VariantDraft(size: s, colour: c),
          ),
        );
      }
    }
    return out;
  }

  void dispose() {
    for (final d in _byKey.values) {
      d.dispose();
    }
  }
}

// ── Step 2: pick sizes & colours ──────────────────────────────────────────

class SizeColourPicker extends StatefulWidget {
  final VariantDrafts drafts;
  final VoidCallback onChanged;
  const SizeColourPicker({
    super.key,
    required this.drafts,
    required this.onChanged,
  });

  @override
  State<SizeColourPicker> createState() => _SizeColourPickerState();
}

class _SizeColourPickerState extends State<SizeColourPicker> {
  final _customSize = TextEditingController();
  final _customColour = TextEditingController();
  String _set = 'Letter';

  @override
  void initState() {
    super.initState();
    // Open on the set the saved sizes come from.
    for (final e in kSizeSets.entries) {
      if (widget.drafts.sizes.any(e.value.contains)) {
        _set = e.key;
        break;
      }
    }
  }

  @override
  void dispose() {
    _customSize.dispose();
    _customColour.dispose();
    super.dispose();
  }

  void _toggle(List<String> list, String v) {
    setState(() {
      final i = list.indexWhere((x) => x.toLowerCase() == v.toLowerCase());
      i >= 0 ? list.removeAt(i) : list.add(v);
    });
    widget.onChanged();
  }

  void _addCustom(List<String> list, TextEditingController c) {
    final v = c.text.trim();
    if (v.isEmpty) return;
    if (!list.any((x) => x.toLowerCase() == v.toLowerCase())) _toggle(list, v);
    c.clear();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.drafts;
    final count = d.rows.length;
    final customSizes = [
      for (final s in d.sizes)
        if (!kSizeSets.values.any((set) => set.contains(s))) s,
    ];
    final customColours = [
      for (final c in d.colours)
        if (!kCommonColours.contains(c)) c,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.straighten_rounded,
          title: 'Sizes',
          trailing: d.sizes.isEmpty ? null : '${d.sizes.length} picked',
        ),
        const SizedBox(height: 10),
        // Size set tabs.
        PillSegmentedControl<String>(
          height: 42,
          value: _set,
          onChanged: (s) => setState(() => _set = s),
          segments: [
            for (final s in kSizeSets.keys) PillSegment(value: s, label: s),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in [...kSizeSets[_set]!, ...customSizes])
              _PickChip(
                label: s,
                selected: d.sizes.contains(s),
                onTap: () => _toggle(d.sizes, s),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _AddField(
          controller: _customSize,
          hint: 'Add your own size (e.g. 5XL, 44)',
          onAdd: () => _addCustom(d.sizes, _customSize),
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          icon: Icons.palette_outlined,
          title: 'Colours',
          trailing: d.colours.isEmpty
              ? 'optional'
              : '${d.colours.length} picked',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in [...kCommonColours, ...customColours])
              _PickChip(
                label: c,
                selected: d.colours.contains(c),
                onTap: () => _toggle(d.colours, c),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _AddField(
          controller: _customColour,
          hint: 'Add your own colour (e.g. Olive)',
          onAdd: () => _addCustom(d.colours, _customColour),
        ),
        const SizedBox(height: 20),
        // What will be created.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.grid_view_rounded, color: AppColors.brand),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  count == 0
                      ? 'Pick at least one size or colour'
                      : '${[if (d.sizes.isNotEmpty) '${d.sizes.length} size${d.sizes.length == 1 ? '' : 's'}', if (d.colours.isNotEmpty) '${d.colours.length} colour${d.colours.length == 1 ? '' : 's'}'].join(' × ')} = $count variant${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (count > 0) ...[
          const SizedBox(height: 6),
          Text(
            'Next: set each one\'s price and opening stock.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  const _SectionTitle({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.brand),
      const SizedBox(width: 8),
      Text(
        title,
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      const Spacer(),
      if (trailing != null)
        Text(
          trailing!,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
    ],
  );
}

class _PickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PickChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.brand : AppColors.surfaceElevated,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _AddField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onAdd;
  const _AddField({
    required this.controller,
    required this.hint,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    textCapitalization: TextCapitalization.words,
    onSubmitted: (_) => onAdd(),
    decoration: InputDecoration(
      hintText: hint,
      isDense: true,
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
      suffixIcon: IconButton(
        tooltip: 'Add',
        onPressed: onAdd,
        icon: const Icon(Icons.add_circle_rounded, color: AppColors.brand),
      ),
    ),
  );
}

// ── Step 3: each variant's prices, code and opening stock ─────────────────

class VariantPriceList extends StatelessWidget {
  final List<VariantDraft> rows;

  /// The product's default prices, shown as hints in empty price fields.
  final String defaultRetail, defaultWholesale, defaultCost;
  final VoidCallback onChanged;
  const VariantPriceList({
    super.key,
    required this.rows,
    required this.defaultRetail,
    required this.defaultWholesale,
    required this.defaultCost,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${rows.length} variant${rows.length == 1 ? '' : 's'}',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Empty prices use the defaults above. Change any to price that size differently.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              for (final r in rows) {
                r.clearPrices();
              }
              onChanged();
            },
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Use defaults for all'),
          ),
        ),
        const SizedBox(height: 4),
        for (final r in rows) ...[
          _VariantCard(
            draft: r,
            defaultRetail: defaultRetail,
            defaultWholesale: defaultWholesale,
            defaultCost: defaultCost,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _VariantCard extends StatelessWidget {
  final VariantDraft draft;
  final String defaultRetail, defaultWholesale, defaultCost;
  const _VariantCard({
    required this.draft,
    required this.defaultRetail,
    required this.defaultWholesale,
    required this.defaultCost,
  });

  InputDecoration _box(String label, {String? hint, String? prefix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceElevated,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
      );

  Widget _money(TextEditingController c, String label, String hint) =>
      TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration: _box(label, hint: hint.isEmpty ? '0' : hint, prefix: '₹ '),
        validator: (v) {
          final t = v?.trim() ?? '';
          return t.isEmpty || double.tryParse(t) != null ? null : 'Number';
        },
      );

  @override
  Widget build(BuildContext context) {
    final saved = draft.id != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  draft.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (saved)
                Text(
                  '${draft.savedStock} in stock',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _money(draft.retail, 'Retail', defaultRetail)),
              const SizedBox(width: 8),
              Expanded(
                child: _money(draft.wholesale, 'Wholesale', defaultWholesale),
              ),
              const SizedBox(width: 8),
              Expanded(child: _money(draft.cost, 'Cost', defaultCost)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: draft.sku,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _box('Code / SKU', hint: 'optional'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: saved
                    ? InputDecorator(
                        decoration: _box('Stock'),
                        child: Text(
                          '${draft.savedStock}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : TextFormField(
                        controller: draft.openingStock,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _box('Opening stock', hint: '0'),
                      ),
              ),
            ],
          ),
          if (saved)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Change stock from Inventory → Adjust.',
                style: TextStyle(color: AppColors.textHint, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
