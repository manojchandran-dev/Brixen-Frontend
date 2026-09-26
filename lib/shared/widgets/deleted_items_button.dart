import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import 'chip_filter_sheet.dart';

/// App-bar button that opens a "Deleted …" sheet for a soft-deleted resource:
/// lists `GET [listPath]?deleted=true` and restores via
/// `POST [restorePath](item)`. Works on raw JSON so every list screen can use
/// it without its own data-layer plumbing.
class DeletedItemsButton extends ConsumerWidget {
  final String title;
  final String listPath;

  /// Restore URL for one deleted item (normally `'$listPath/${item['id']}/restore'`).
  final String Function(Map<String, dynamic> item) restorePath;
  final String Function(Map<String, dynamic> item) labelOf;
  final String? Function(Map<String, dynamic> item)? subtitleOf;

  /// Refresh the screen's own list after a restore.
  final VoidCallback onRestored;

  /// true: the square button used beside a search box (next to a filter
  /// button); false: the smaller app-bar button.
  final bool inline;

  const DeletedItemsButton({
    super.key,
    required this.title,
    required this.listPath,
    required this.restorePath,
    required this.labelOf,
    this.subtitleOf,
    required this.onRestored,
    this.inline = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (inline) {
      return HeaderIconButton(
        tooltip: title,
        icon: Icons.restore_from_trash_rounded,
        onTap: () => _open(context, ref.read(dioProvider)),
      );
    }
    return Tooltip(
      message: title,
      child: GestureDetector(
        onTap: () => _open(context, ref.read(dioProvider)),
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.restore_from_trash_rounded,
            size: 19,
            color: AppColors.brand,
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _load(Dio dio) async {
    try {
      final resp = await dio.get(
        listPath,
        queryParameters: {'deleted': 'true', 'limit': 100},
      );
      final data = resp.data['data'] ?? resp.data;
      final list = data is List ? data : (data['items'] as List? ?? const []);
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  void _open(BuildContext context, Dio dio) {
    var future = _load(dio);
    final restoring = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          Future<void> restore(Map<String, dynamic> item) async {
            final key = restorePath(item);
            setSheet(() => restoring.add(key));
            try {
              // The item's own company, not the list filter: a superadmin
              // browsing "All companies" has no company_id to send otherwise.
              await dio.post(
                key,
                queryParameters: {
                  if (item['company_id'] != null)
                    'company_id': item['company_id'].toString(),
                },
              );
              onRestored();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${labelOf(item)}" restored')),
                );
              }
              if (sheetCtx.mounted) setSheet(() => future = _load(dio));
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e is DioException ? mapDioError(e).message : e.toString(),
                    ),
                    backgroundColor: AppColors.dangerFill,
                  ),
                );
              }
            } finally {
              restoring.remove(key);
              if (sheetCtx.mounted) setSheet(() {});
            }
          }

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetCtx).size.height * 0.8,
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: future,
                builder: (_, snap) {
                  final items = snap.data;
                  final Widget body;
                  if (snap.connectionState != ConnectionState.done) {
                    body = const DeletedSheetMessage.loading();
                  } else if (snap.hasError) {
                    body = DeletedSheetMessage(
                      icon: Icons.cloud_off_rounded,
                      text: snap.error.toString(),
                    );
                  } else if (items!.isEmpty) {
                    body = const DeletedSheetMessage(
                      icon: Icons.delete_outline_rounded,
                      text: 'Trash is empty.\nDeleted items will show up here.',
                    );
                  } else {
                    body = ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return DeletedItemTile(
                          title: labelOf(item),
                          subtitle: subtitleOf?.call(item),
                          busy: restoring.contains(restorePath(item)),
                          onRestore: () => restore(item),
                        );
                      },
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DeletedSheetHeader(title: title, count: items?.length),
                      Flexible(child: body),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Sheet pieces, shared with the Companies "Deleted companies" sheet ────────

/// Icon badge + title + count pill + close button. Use with
/// `showModalBottomSheet(showDragHandle: true)`.
class DeletedSheetHeader extends StatelessWidget {
  final String title;
  final int? count;
  final String subtitle;
  const DeletedSheetHeader({
    super.key,
    required this.title,
    this.count,
    this.subtitle = 'Restore brings an item back exactly as it was',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 8, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brand, AppColors.brandDeep],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restore_from_trash_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (count != null && count! > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: AppColors.brand,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Loading spinner, or an icon + message for the empty / error state.
class DeletedSheetMessage extends StatelessWidget {
  final IconData? icon;
  final String text;
  const DeletedSheetMessage({
    super.key,
    required IconData this.icon,
    required this.text,
  });
  const DeletedSheetMessage.loading({super.key}) : icon = null, text = '';

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 44),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.brand, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

/// One deleted item: greyed initials badge, title, subtitle, Restore button.
class DeletedItemTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool busy;
  final VoidCallback onRestore;
  const DeletedItemTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.busy,
    required this.onRestore,
  });

  String get _initials {
    final words = title
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].substring(0, words[0].length.clamp(0, 2)).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          // Greyed badge signals "in trash".
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.textHint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _initials,
              style: TextStyle(
                color: AppColors.textSecondary,
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
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: FilledButton.icon(
              onPressed: busy ? null : onRestore,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                disabledBackgroundColor: AppColors.brand.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.restore_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
              label: const Text(
                'Restore',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
