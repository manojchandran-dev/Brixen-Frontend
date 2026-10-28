import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';

/// A piece-rate employee who makes a product, with their rate.
class ProductMaker {
  final String id, code, name;
  final double? rate;

  /// The rate is per dozen (else per piece).
  final bool perDozen;
  const ProductMaker({
    required this.id,
    required this.code,
    required this.name,
    this.rate,
    this.perDozen = false,
  });

  factory ProductMaker.fromJson(Map<String, dynamic> j) => ProductMaker(
    id: j['id'].toString(),
    code: (j['employee_code'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    rate: (j['rate'] as num?)?.toDouble(),
    perDozen: j['per'] == 'DOZEN',
  );

  /// "₹5 per dozen".
  String get rateLabel => rate == null
      ? 'No rate set'
      : '${rupeesExact(rate!)} ${perDozen ? 'per dozen' : 'per piece'}';
}

/// A product's makers, whether it sells by the dozen, and the piece-rate
/// employees who could be picked.
typedef ProductMakers = ({
  bool soldByDozen,
  List<ProductMaker> makers,
  List<ProductMaker> choices,
});

ProductMakers _parse(Response resp) {
  final d =
      ((resp.data is Map ? resp.data['data'] : null) ?? resp.data)
          as Map<String, dynamic>;
  List<ProductMaker> list(Object? v) => [
    for (final e in (v as List? ?? const []))
      ProductMaker.fromJson((e as Map).cast<String, dynamic>()),
  ];
  return (
    soldByDozen: d['sold_by_dozen'] == true,
    makers: list(d['makers']),
    choices: list(d['choices']),
  );
}

final productMakersProvider = FutureProvider.autoDispose
    .family<ProductMakers, String>((ref, productId) async {
      try {
        return _parse(
          await ref
              .read(dioProvider)
              .get(ApiEndpoints.productMakers(productId)),
        );
      } on DioException catch (e) {
        throw mapDioError(e);
      }
    });

/// "Made by" on a product: the piece-rate employees paid when it sells —
/// pieces sold (× 12 if it sells by the dozen) × each one's own rate, in the
/// salary run of the sale's date.
class ProductMakersSection extends ConsumerWidget {
  final String productId;
  const ProductMakersSection({super.key, required this.productId});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ProductMakers data,
  ) async {
    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MakersPicker(
        choices: data.choices,
        selected: {for (final m in data.makers) m.id},
      ),
    );
    if (picked == null) return;
    try {
      await ref
          .read(dioProvider)
          .put(
            ApiEndpoints.productMakers(productId),
            data: {
              'employee_ids': [for (final id in picked) int.parse(id)],
            },
          );
      ref.invalidate(productMakersProvider(productId));
    } on DioException catch (e) {
      if (context.mounted) showErrorDialog(context, mapDioError(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(moduleAccessProvider('Products')).edit;
    final async = ref.watch(productMakersProvider(productId));
    final color = AppColors.positiveDeep;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: async.when(
        skipError: true,
        loading: () => const Padding(
          padding: EdgeInsets.all(8),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => Text(
          '$e',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        data: (d) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.engineering_rounded, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Made by (piece rate)',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (canEdit)
                  TextButton.icon(
                    onPressed: () => _edit(context, ref, d),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Change'),
                  ),
              ],
            ),
            Text(
              d.soldByDozen
                  ? 'Sold by the dozen: each sold counts 12 pieces.'
                  : 'Sold by the piece.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (d.makers.isEmpty)
              Text(
                d.choices.isEmpty
                    ? 'No piece-rate employees yet — set an employee\'s salary '
                          'type to Piece Rate first.'
                    : 'Nobody yet. Pick who makes it, so they\'re paid when it '
                          'sells.',
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
              )
            else
              for (final m in d.makers)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: color,
                        child: Text(
                          m.name.isEmpty ? '?' : m.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        m.rateLabel,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Tick the piece-rate employees who make the product. Pops the chosen ids.
class _MakersPicker extends StatefulWidget {
  final List<ProductMaker> choices;
  final Set<String> selected;
  const _MakersPicker({required this.choices, required this.selected});

  @override
  State<_MakersPicker> createState() => _MakersPickerState();
}

class _MakersPickerState extends State<_MakersPicker> {
  late final Set<String> _picked = {...widget.selected};

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Who makes this product?',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Each one is paid the pieces sold × their own rate.',
            style: TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (widget.choices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No piece-rate employees yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final c in widget.choices)
                  CheckboxListTile(
                    value: _picked.contains(c.id),
                    onChanged: (v) => setState(
                      () =>
                          v == true ? _picked.add(c.id) : _picked.remove(c.id),
                    ),
                    title: Text(c.name),
                    subtitle: Text('${c.code} · ${c.rateLabel}'),
                    activeColor: AppColors.positiveDeep,
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_picked),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
