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

class PushNotificationsPage extends ConsumerStatefulWidget {
  const PushNotificationsPage({super.key});

  @override
  ConsumerState<PushNotificationsPage> createState() =>
      _PushNotificationsPageState();
}

class _PushNotificationsPageState extends ConsumerState<PushNotificationsPage> {
  final _searchCtrl = TextEditingController();
  CommunicationStatus? _statusFilter;
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

  void _onStatusSelected(CommunicationStatus? status) {
    setState(() => _statusFilter = status);
    _reload();
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
        title: Text(
          'Push Notifications',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: SearchField(
              controller: _searchCtrl,
              hintText: 'Search notifications...',
              onChanged: _onSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _statusFilter == null,
                    onTap: () => _onStatusSelected(null),
                  ),
                  for (final s in CommunicationStatus.values.where(
                    (s) => s != CommunicationStatus.published,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: s.name[0].toUpperCase() + s.name.substring(1),
                        selected: _statusFilter == s,
                        onTap: () => _onStatusSelected(s),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: notificationsAsync.when(
              loading: () => const SkeletonListView(),
              error: (e, _) => ErrorCard(error: e, onRetry: _reload),
              data: (list) {
                if (list.isEmpty) {
                  final filtered =
                      _statusFilter != null ||
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
                          filtered ? 'No results' : 'No push notifications yet',
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

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _PushNotificationCard(index: i, notification: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : cs.onSurfaceVariant,
          ),
        ),
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
      child: RichCardShell.tinted(
        index: index,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (notification.message.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                // A fixed height, not just maxLines — `RichCardShell` wraps
                // this card in `IntrinsicHeight`, whose dry-layout pass
                // under-measures a `maxLines`+`ellipsis` Text vs. its real
                // layout pass (a known Flutter interaction), which is what
                // produced the "bottom overflowed" banner here. Pinning the
                // height removes the ambiguity between those two passes.
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
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'Recipients',
                      value: '${notification.recipients}',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatBox(
                      label: 'Delivered',
                      value: '${notification.delivered}',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatBox(
                      label: 'Opened',
                      value: '${notification.opened}',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatBox(
                      label: 'Failed',
                      value: '${notification.failed}',
                      alert: notification.failed > 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    notification.status == CommunicationStatus.scheduled
                        ? Icons.schedule_rounded
                        : Icons.send_rounded,
                    size: 12,
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
                  const SizedBox(width: 8),
                  NotificationStatusBadge(status: notification.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The list's copy of a notification is a lighter payload than the
/// single-record endpoint (no per-company delivery breakdown, for one) —
/// this shows the passed-in copy immediately so the sheet never opens
/// blank, then re-fetches by id in the background and swaps in the fresh
/// record once it lands.
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
        DetailSection(
          title: 'Details',
          items: [
            DetailRow(
              icon: Icons.message_outlined,
              label: 'Message',
              value: n.message,
              stacked: true,
            ),
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
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  // Every box shares the same app-brand tint — only a genuine problem
  // (failed > 0) breaks from that, into the app's own existing danger
  // color, not an arbitrary new one.
  final bool alert;
  const _StatBox({
    required this.label,
    required this.value,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = alert ? AppColors.accentRose : AppColors.brand;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.ink.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// One company's delivery outcome — company name, its status, and (if it
/// was tapped) a small "Opened" badge, so the admin can see exactly who
/// got the push and whether they engaged with it.
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
                    style: TextStyle(color: AppColors.accentRose, fontSize: 11),
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
