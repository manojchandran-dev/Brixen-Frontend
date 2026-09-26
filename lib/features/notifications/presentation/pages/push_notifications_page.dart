import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/chip_filter_sheet.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/detail_sheet.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../../shared/widgets/search_field.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../data/repositories/push_notifications_repository_impl.dart';
import '../../domain/entities/push_notification.dart';
import '../providers/push_notifications_provider.dart';
import '../widgets/notification_labels.dart';
import '../widgets/notification_status_badge.dart';
import '../../../../shared/widgets/list_count_bar.dart';
import '../../../../shared/widgets/module_title.dart';

class PushNotificationsPage extends ConsumerStatefulWidget {
  const PushNotificationsPage({super.key});

  @override
  ConsumerState<PushNotificationsPage> createState() =>
      _PushNotificationsPageState();
}

class _PushNotificationsPageState extends ConsumerState<PushNotificationsPage> {
  final _searchCtrl = TextEditingController();
  CommunicationStatus? _statusFilter;
  // Applied to the loaded list; status and search go to the API.
  NotificationPriority? _priorityFilter;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // Both the status chip and the search box are applied server-side (see
  // `PushNotificationsNotifier.reload`) — filtering the already-loaded list
  // client-side only ever saw the first page's 100 notifications, silently
  // missing anything older than that under the selected status.
  void _reload() {
    ref
        .read(pushNotificationsProvider.notifier)
        .reload(status: _statusFilter?.name, search: _searchCtrl.text.trim());
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _reload);
  }

  void _openFilter() {
    showChipFilterSheet(
      context,
      title: 'Filter notifications',
      sections: [
        FilterSection(
          key: 'status',
          title: 'Status',
          options: [
            for (final s in CommunicationStatus.values)
              if (s != CommunicationStatus.published)
                (s, s.name[0].toUpperCase() + s.name.substring(1)),
          ],
        ),
        FilterSection(
          key: 'priority',
          title: 'Priority',
          options: [
            for (final p in NotificationPriority.values) (p, priorityLabel(p)),
          ],
        ),
      ],
      selected: {'status': _statusFilter, 'priority': _priorityFilter},
      onApply: (chosen) {
        final status = chosen['status'] as CommunicationStatus?;
        final statusChanged = status != _statusFilter;
        setState(() {
          _statusFilter = status;
          _priorityFilter = chosen['priority'] as NotificationPriority?;
        });
        if (statusChanged) _reload();
      },
      onClear: () {
        setState(() {
          _statusFilter = null;
          _priorityFilter = null;
        });
        _reload();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.isSuperAdmin) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final notificationsAsync = ref.watch(pushNotificationsProvider);

    return Scaffold(
      extendBody: true,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(activeIndex: 0),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (ctx) => GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.all(8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.shadows([
                  BoxShadow(
                    color: AppColors.shadowDark.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]),
              ),
              child: Icon(Icons.menu_rounded, size: 18, color: AppColors.ink),
            ),
          ),
        ),
        title: ModuleTitle(
          title: 'Push Notifications',
          subtitle: 'Alerts sent to company apps',
        ),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRouter.createPushNotification),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brand, AppColors.brandDeep],
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 20,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: SearchField(
                    controller: _searchCtrl,
                    hintText: 'Search notifications...',
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 10),
                HeaderIconButton(
                  tooltip: 'Filter notifications',
                  icon: Icons.filter_list_rounded,
                  active: _statusFilter != null || _priorityFilter != null,
                  onTap: _openFilter,
                ),
              ],
            ),
          ),
          Expanded(
            // reload() keeps the previous list in the loading state — show
            // the skeleton anyway, so a search/filter visibly reloads.
            child: notificationsAsync.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const SkeletonListView(),
              error: (e, _) => ErrorCard(error: e, onRetry: _reload),
              data: (all) {
                final list = _priorityFilter == null
                    ? all
                    : all.where((n) => n.priority == _priorityFilter).toList();
                if (list.isEmpty) {
                  final filtered =
                      _statusFilter != null ||
                      _priorityFilter != null ||
                      _searchCtrl.text.trim().isNotEmpty;
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 56,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          filtered
                              ? 'No notifications match'
                              : 'No push notifications yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    ListCountBar(
                      label: 'Total Notifications',
                      count: list.length,
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _PushNotificationCard(
                          index: i,
                          notification: list[i],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PushNotificationCard extends ConsumerWidget {
  final PushNotification notification;
  final int index;
  const _PushNotificationCard({
    required this.index,
    required this.notification,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd MMM yyyy, h:mm a');
    // The card's own accent (its border and tint) — the status shows in
    // the pill.
    final color = RichCardShell.accentFor(index);
    return SwipeActions(
      onTap: () => showDetailSheet(
        context,
        (ctx) => _NotificationDetailBody(notification: notification),
      ),
      actions: [
        SwipeAction(
          icon: Icons.edit_outlined,
          label: 'Edit',
          color: AppColors.accentIndigo,
          onTap: () async {
            // The list's copy is a lighter payload than the single-record
            // endpoint — re-fetch by id so editing starts from the actual
            // current record, falling back to what's already on hand if
            // that fails rather than blocking the edit entirely.
            PushNotification toEdit = notification;
            try {
              toEdit = await ref
                  .read(pushNotificationsRepositoryProvider)
                  .getById(notification.id);
            } catch (_) {}
            if (context.mounted) {
              context.push(AppRouter.createPushNotification, extra: toEdit);
            }
          },
        ),
        SwipeAction(
          icon: Icons.copy_rounded,
          label: 'Duplicate',
          color: AppColors.accentGold,
          onTap: () => ref
              .read(pushNotificationsProvider.notifier)
              .duplicate(notification.id),
        ),
        if (notification.status == CommunicationStatus.scheduled)
          SwipeAction(
            icon: Icons.cancel_outlined,
            label: 'Cancel',
            color: AppColors.brandBlack,
            onTap: () async {
              final ok = await showConfirmDialog(
                context,
                title: 'Cancel Notification',
                message:
                    'Cancel this scheduled notification? It will never be sent.',
                confirmLabel: 'Cancel It',
                isDestructive: true,
              );
              if (ok) {
                await ref
                    .read(pushNotificationsProvider.notifier)
                    .cancel(notification.id);
              }
            },
          ),
        SwipeAction(
          icon: Icons.delete_outline,
          label: 'Delete',
          color: AppColors.accentRose,
          onTap: () async {
            final ok = await showConfirmDialog(
              context,
              title: 'Delete Notification',
              message: 'Delete "${notification.title}"? This cannot be undone.',
              confirmLabel: 'Delete',
              isDestructive: true,
            );
            if (ok) {
              await ref
                  .read(pushNotificationsProvider.notifier)
                  .delete(notification.id);
            }
          },
        ),
      ],
      // Background cycles the theme accents by position, like the Companies
      // list; the status shows in the icon badge and pill.
      child: RichCardShell.tinted(
        index: index,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.accentGradient(color),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppColors.shadows([
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]),
                    ),
                    child: Icon(
                      _statusIcon(notification.status),
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (notification.message.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          // Fixed height, not just maxLines: RichCardShell's
                          // IntrinsicHeight under-measures a maxLines +
                          // ellipsis Text (a known Flutter interaction), which
                          // caused a "bottom overflowed" banner here.
                          SizedBox(
                            height: 34,
                            child: Text(
                              notification.message.trim(),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.ink.withValues(alpha: 0.6),
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  NotificationStatusBadge(status: notification.status),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _MiniStat(
                      icon: Icons.groups_rounded,
                      value: notification.recipients,
                      label: 'Recipients',
                      color: AppColors.brand,
                    ),
                    _MiniStat(
                      icon: Icons.done_all_rounded,
                      value: notification.delivered,
                      label: 'Delivered',
                      color: AppColors.positive,
                    ),
                    _MiniStat(
                      icon: Icons.visibility_rounded,
                      value: notification.opened,
                      label: 'Opened',
                      color: AppColors.accentIndigo,
                    ),
                    _MiniStat(
                      icon: Icons.error_outline_rounded,
                      value: notification.failed,
                      label: 'Failed',
                      color: notification.failed > 0
                          ? AppColors.accentRose
                          : AppColors.textHint,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    notification.status == CommunicationStatus.scheduled
                        ? Icons.schedule_rounded
                        : Icons.access_time_rounded,
                    size: 13,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      notification.status == CommunicationStatus.scheduled &&
                              notification.scheduledAt != null
                          ? 'Scheduled for ${fmt.format(notification.scheduledAt!)}'
                          : notification.sentAt != null
                          ? 'Sent ${fmt.format(notification.sentAt!)}'
                          : 'Created ${fmt.format(notification.createdAt)}',
                      style: TextStyle(fontSize: 11, color: AppColors.textHint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (notification.priority != NotificationPriority.normal) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (notification.priority ==
                                        NotificationPriority.urgent
                                    ? AppColors.accentRose
                                    : AppColors.accentGold)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.priority_high_rounded,
                            size: 11,
                            color:
                                notification.priority ==
                                    NotificationPriority.urgent
                                ? AppColors.accentRose
                                : AppColors.accentGold,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            priorityLabel(notification.priority),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color:
                                  notification.priority ==
                                      NotificationPriority.urgent
                                  ? AppColors.accentRose
                                  : AppColors.accentGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _statusIcon(CommunicationStatus s) => switch (s) {
    CommunicationStatus.draft => Icons.edit_note_rounded,
    CommunicationStatus.scheduled => Icons.schedule_send_rounded,
    CommunicationStatus.sending => Icons.send_rounded,
    CommunicationStatus.sent ||
    CommunicationStatus.published => Icons.mark_email_read_rounded,
    CommunicationStatus.failed => Icons.error_outline_rounded,
    CommunicationStatus.cancelled => Icons.cancel_schedule_send_rounded,
  };
}

/// One figure in a card's stats strip: icon, number, label.
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

/// The list's copy of a notification is a lighter payload than the
/// single-record endpoint (no per-company delivery breakdown, for one) —
/// this shows the passed-in copy immediately so the sheet never opens
/// blank, then re-fetches by id in the background and swaps in the fresh
/// record once it lands.
/// The message as recipients see it — laid out like a phone's push
/// notification (app row, bold title, full message), under a "Message"
/// heading matching the other sections.
class _MessagePreview extends StatelessWidget {
  final String title;
  final String message;
  const _MessagePreview({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Message',
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        // Rounded corners + a one-sided border can't share a BoxDecoration
        // (Flutter asserts) — so the accent border sits inside a clip.
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.shadows([
              BoxShadow(
                color: AppColors.shadowDark.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.brand, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.accentGradient(AppColors.brand),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.notifications_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Brixen · Push notification',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (message.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    // Selectable so the text can be copied.
                    SelectableText(
                      message.trim(),
                      style: TextStyle(
                        color: AppColors.ink.withValues(alpha: 0.8),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationDetailBody extends ConsumerStatefulWidget {
  final PushNotification notification;
  const _NotificationDetailBody({required this.notification});

  @override
  ConsumerState<_NotificationDetailBody> createState() =>
      _NotificationDetailBodyState();
}

class _NotificationDetailBodyState
    extends ConsumerState<_NotificationDetailBody> {
  late PushNotification _n = widget.notification;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final fresh = await ref
          .read(pushNotificationsRepositoryProvider)
          .getById(widget.notification.id);
      if (mounted) setState(() => _n = fresh);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final n = _n;
    final fmt = DateFormat('dd MMM yyyy, h:mm a');
    return DetailSheetScaffold(
      avatarIcon: Icons.notifications_rounded,
      avatarGradient: AppColors.accentGradient(AppColors.brand),
      title: n.title,
      subtitle: priorityLabel(n.priority),
      statusRow: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.campaign_rounded,
              color: AppColors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            NotificationStatusBadge(status: n.status),
            const Spacer(),
            Text(
              '${n.recipients} recipients',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      sections: [
        _MessagePreview(title: n.title, message: n.message),
        DetailSection(
          title: 'Details',
          items: [
            DetailRow(
              icon: Icons.touch_app_outlined,
              label: 'Open On Tap',
              value: openOnTapLabel(n.openOnTap),
              iconColor: AppColors.positive,
            ),
            DetailRow(
              icon: Icons.person_outline,
              label: 'Created By',
              value: n.createdBy,
            ),
          ],
        ),
        DetailSection(
          title: 'Audience',
          items: [
            DetailRow(
              icon: Icons.groups_outlined,
              label: 'Target',
              value: audienceLabel(n.audience),
            ),
          ],
        ),
        DetailSection(
          title: 'Delivery',
          items: [
            DetailRow(
              icon: Icons.groups_rounded,
              label: 'Total Recipients',
              value: '${n.recipients}',
            ),
            DetailRow(
              icon: Icons.check_circle_outline,
              label: 'Delivered',
              value: '${n.delivered}',
              iconColor: AppColors.positive,
            ),
            DetailRow(
              icon: Icons.touch_app_outlined,
              label: 'Opened',
              value: '${n.opened}',
              iconColor: AppColors.brand,
            ),
            DetailRow(
              icon: Icons.error_outline,
              label: 'Failed',
              value: '${n.failed}',
              iconColor: AppColors.accentRose,
            ),
          ],
        ),
        if (n.companyDeliveries.isNotEmpty)
          DetailSection(
            title: 'Recipients',
            items: [
              for (final d in n.companyDeliveries)
                _CompanyDeliveryRow(delivery: d),
            ],
          ),
        DetailSection(
          title: 'Timeline',
          items: [
            DetailRow(
              icon: Icons.add_circle_outline,
              label: 'Created',
              value: fmt.format(n.createdAt),
            ),
            if (n.scheduledAt != null)
              DetailRow(
                icon: Icons.schedule_outlined,
                label: 'Scheduled',
                value: fmt.format(n.scheduledAt!),
              ),
            if (n.sentAt != null)
              DetailRow(
                icon: Icons.send_outlined,
                label: 'Sent',
                value: fmt.format(n.sentAt!),
              ),
          ],
        ),
      ],
    );
  }
}

/// A single Recipients/Delivered/Failed count — its own bordered, centered
/// box instead of one continuous row split by divider lines, so each
/// number reads as a distinct stat rather than three cells of a table.
class _CompanyDeliveryRow extends StatelessWidget {
  final CompanyDeliveryStatus delivery;
  const _CompanyDeliveryRow({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final status = delivery.status.toLowerCase();
    final failed = status == 'failed';
    final delivered = status == 'delivered' || delivery.deliveredAt != null;
    final dotColor = failed
        ? AppColors.accentRose
        : (delivered ? AppColors.positive : AppColors.textHint);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delivery.companyName,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (failed &&
                    delivery.error != null &&
                    delivery.error!.isNotEmpty)
                  Text(
                    delivery.error!,
                    style: TextStyle(color: AppColors.ink, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (delivery.openedAt != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Opened',
                style: TextStyle(
                  color: AppColors.brand,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Text(
              status.isEmpty
                  ? '—'
                  : status[0].toUpperCase() + status.substring(1),
              style: TextStyle(
                color: dotColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
