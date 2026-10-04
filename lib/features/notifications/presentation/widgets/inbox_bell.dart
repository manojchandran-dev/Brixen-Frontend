import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../providers/inbox_provider.dart';

/// Dashboard bell for company users: unread count badge; tap → inbox sheet.
class InboxBell extends ConsumerWidget {
  const InboxBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(inboxProvider).valueOrNull?.unread ?? 0;
    return GestureDetector(
      onTap: () => showInboxSheet(context),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: AppColors.ink,
            size: 24,
            semanticLabel: unread > 0
                ? 'Notifications, $unread unread'
                : 'Notifications',
          ),
          if (unread > 0)
            Positioned(
              top: -6,
              right: -8,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.positive,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showInboxSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) => const _InboxSheet(),
);

class _InboxSheet extends ConsumerStatefulWidget {
  const _InboxSheet();

  @override
  ConsumerState<_InboxSheet> createState() => _InboxSheetState();
}

class _InboxSheetState extends ConsumerState<_InboxSheet> {
  bool _markingAll = false;

  /// Marked read in this sheet, shown read before the reload confirms it.
  final Set<String> _readNow = {};

  /// The card showing its full message.
  String? _expanded;

  bool _isRead(InboxItem i) => i.read || _readNow.contains(i.id);

  /// Tap: stays in the sheet — expands the card (full message) and, if it
  /// was unread, marks it read (`/{id}/opened`).
  Future<void> _open(InboxItem item) async {
    final wasUnread = !_isRead(item);
    setState(() {
      _expanded = _expanded == item.id ? null : item.id;
      if (wasUnread) _readNow.add(item.id);
    });
    if (!wasUnread) return;
    try {
      await markInboxItemRead(ref, item.id);
      ref.invalidate(inboxProvider); // bell badge + counts
    } catch (_) {
      if (mounted) setState(() => _readNow.remove(item.id));
    }
  }

  Future<void> _readAll() async {
    setState(() => _markingAll = true);
    try {
      await markAllInboxRead(ref);
      ref.invalidate(inboxProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.dangerFill),
        );
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(inboxProvider);
    final inbox = async.valueOrNull;
    final unread =
        ((inbox?.unread ?? 0) -
                (inbox?.items ?? const <InboxItem>[])
                    .where((i) => !i.read && _readNow.contains(i.id))
                    .length)
            .clamp(0, 1 << 30);
    final items = (inbox?.items ?? const <InboxItem>[])
        .where((i) => !_unreadOnly || !i.read)
        .toList();

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.88,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ── Header: icon, title + count, mark-all pill ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.brand, AppColors.brandDeep],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        inbox == null
                            ? 'Loading…'
                            : unread == 0
                            ? 'All caught up'
                            : '$unread unread',
                        style: TextStyle(
                          color: unread > 0
                              ? AppColors.positive
                              : AppColors.textHint,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread > 0)
                  Material(
                    color: AppColors.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: _markingAll ? null : _readAll,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _markingAll
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.done_all_rounded,
                                    size: 16,
                                    color: AppColors.brand,
                                  ),
                            const SizedBox(width: 6),
                            const Text(
                              'Mark all as read',
                              style: TextStyle(
                                color: AppColors.brand,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── All / Unread segmented tabs ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  for (final (only, label) in [
                    (false, 'All'),
                    (true, unread > 0 ? 'Unread · $unread' : 'Unread'),
                  ])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _unreadOnly = only),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _unreadOnly == only
                                ? AppColors.surface
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _unreadOnly == only
                                ? AppColors.shadows([
                                    BoxShadow(
                                      color: AppColors.shadowDark.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ])
                                : null,
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: _unreadOnly == only
                                  ? AppColors.ink
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: _unreadOnly == only
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: inbox == null && async.hasError
                ? ErrorCard(
                    error: async.error!,
                    onRetry: () => ref.invalidate(inboxProvider),
                  )
                : inbox == null
                ? const SkeletonListView(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
                  )
                : items.isEmpty
                ? _InboxEmpty(unreadOnly: _unreadOnly)
                : RefreshIndicator(
                    onRefresh: () => ref.refresh(inboxProvider.future),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                      children: [
                        for (final (i, item) in items.indexed) ...[
                          // Day heading whenever the day changes.
                          if (i == 0 ||
                              _dayLabel(items[i - 1].sentAt) !=
                                  _dayLabel(item.sentAt))
                            _DayHeading(_dayLabel(item.sentAt)),
                          _InboxTile(
                            item: item,
                            read: _isRead(item),
                            expanded: _expanded == item.id,
                            onTap: () => _open(item),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

final _dayFmt = DateFormat('EEEE, d MMM');
final _timeFmt = DateFormat('h:mm a');

/// "Today" / "Yesterday" / "Wednesday, 24 Sep" — the list's group headings.
String _dayLabel(DateTime? t) {
  if (t == null) return 'Earlier';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(DateTime(t.year, t.month, t.day)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return _dayFmt.format(t);
}

class _DayHeading extends StatelessWidget {
  final String label;
  const _DayHeading(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: AppColors.border)),
        ],
      ),
    );
  }
}

class _InboxEmpty extends StatelessWidget {
  final bool unreadOnly;
  const _InboxEmpty({required this.unreadOnly});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.positive.withValues(alpha: 0.12),
              ),
              child: Icon(
                unreadOnly
                    ? Icons.mark_email_read_outlined
                    : Icons.notifications_off_outlined,
                size: 34,
                color: AppColors.positive,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              unreadOnly ? "You're all caught up" : 'No notifications yet',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unreadOnly
                  ? 'Nothing new since you last checked.'
                  : 'Messages from Brixen will show up here.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// One notification: white card; unread = green edge bar, bold title and
/// dot; urgent = dark badge + "Urgent" tag.
class _InboxTile extends StatelessWidget {
  final InboxItem item;
  final bool read;
  final bool expanded;
  final VoidCallback onTap;
  const _InboxTile({
    required this.item,
    required this.read,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final urgent = item.priority == 'urgent' || item.priority == 'high';
    final badge = urgent ? AppColors.brandDeep : AppColors.brand;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ]),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Unread edge bar.
                Container(
                  width: 4,
                  color: read ? Colors.transparent : AppColors.positive,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 14, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: read ? badge.withValues(alpha: 0.12) : badge,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            urgent
                                ? Icons.priority_high_rounded
                                : Icons.campaign_rounded,
                            color: read ? badge : Colors.white,
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
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.ink,
                                        fontSize: 14,
                                        fontWeight: read
                                            ? FontWeight.w600
                                            : FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (!read)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: const BoxDecoration(
                                        color: AppColors.positive,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              if (item.message.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.message,
                                  maxLines: expanded ? null : 2,
                                  overflow: expanded
                                      ? null
                                      : TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 12,
                                    color: AppColors.textHint,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.sentAt == null
                                        ? '—'
                                        : _timeFmt.format(item.sentAt!),
                                    style: TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (urgent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.brandDeep.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Urgent',
                                        style: TextStyle(
                                          color: AppColors.brandDeep,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
