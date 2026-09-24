import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/widgets/deleted_items_button.dart';
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
import '../../../../shared/widgets/picked_image.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../../shared/widgets/search_field.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/push_notification.dart' show CommunicationStatus;
import '../providers/announcements_provider.dart';
import '../widgets/notification_labels.dart';
import '../widgets/notification_status_badge.dart';

class AnnouncementsPage extends ConsumerStatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  ConsumerState<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends ConsumerState<AnnouncementsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.isSuperAdmin) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      extendBody: true,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(activeIndex: 0),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: Builder(builder: (ctx) => GestureDetector(
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
                BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 4)),
              ]),
            ),
            child: Icon(Icons.menu_rounded, size: 18, color: AppColors.ink),
          ),
        )),
        title: Text('Announcements', style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          DeletedItemsButton(
            title: 'Deleted announcements',
            listPath: ApiEndpoints.announcements,
            restorePath: (a) => '${ApiEndpoints.announcements}/${a['id']}/restore',
            labelOf: (a) => (a['title'] ?? '').toString(),
            onRestored: () => ref.invalidate(announcementsProvider),
          ),
          GestureDetector(
            onTap: () => context.push(AppRouter.createAnnouncement),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.brand, AppColors.brandDeep]),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.add_rounded, size: 20, color: AppColors.white),
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
              hintText: 'Search announcements...',
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: announcementsAsync.when(
              loading: () => const SkeletonListView(),
              error: (e, _) => ErrorCard(error: e, onRetry: () => ref.invalidate(announcementsProvider)),
              data: (list) {
                final query = _searchCtrl.text.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? list
                    : list.where((a) => a.title.toLowerCase().contains(query)).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign_outlined, size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          list.isEmpty ? 'No announcements yet' : 'No results',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _AnnouncementCard(index: i, announcement: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends ConsumerWidget {
  final Announcement announcement;
  final int index;
  const _AnnouncementCard({required this.index, required this.announcement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd MMM yyyy');
    return SwipeActions(
      onTap: () => _showDetail(context),
      actions: [
        SwipeAction(
          icon: Icons.edit_outlined,
          label: 'Edit',
          color: AppColors.accentIndigo,
          onTap: () => context.push(AppRouter.createAnnouncement, extra: announcement),
        ),
        SwipeAction(
          icon: Icons.copy_rounded,
          label: 'Duplicate',
          color: AppColors.accentGold,
          onTap: () => ref.read(announcementsProvider.notifier).duplicate(announcement.id),
        ),
        if (announcement.status == CommunicationStatus.published)
          SwipeAction(
            icon: Icons.visibility_off_outlined,
            label: 'Unpublish',
            color: AppColors.brandBlack,
            onTap: () async {
              final ok = await showConfirmDialog(
                context,
                title: 'Unpublish Announcement',
                message: 'Unpublish "${announcement.title}"? It will no longer be visible to companies.',
                confirmLabel: 'Unpublish',
                isDestructive: true,
              );
              if (ok) await ref.read(announcementsProvider.notifier).unpublish(announcement.id);
            },
          ),
        SwipeAction(
          icon: Icons.delete_outline,
          label: 'Delete',
          color: AppColors.accentRose,
          onTap: () async {
            final ok = await showConfirmDialog(
              context,
              title: 'Delete Announcement',
              message: 'Delete "${announcement.title}"? This cannot be undone.',
              confirmLabel: 'Delete',
              isDestructive: true,
            );
            if (ok) await ref.read(announcementsProvider.notifier).delete(announcement.id);
          },
        ),
      ],
      child: RichCardShell.tinted(index: index, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (announcement.bannerUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: pickedImage(announcement.bannerUrl!, width: 56, height: 56),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  NotificationStatusBadge(status: announcement.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                announcement.shortDescription,
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              StatGrid(items: [
                StatGridItem(label: 'Audience', value: audienceLabel(announcement.audience)),
                StatGridItem(label: 'Views', value: '${announcement.views}'),
                StatGridItem(label: 'CTA', value: announcement.ctaLabel ?? '—'),
              ]),
              const SizedBox(height: 8),
              Text(
                announcement.publishedAt != null
                    ? 'Published ${fmt.format(announcement.publishedAt!)}'
                    : announcement.scheduledAt != null
                        ? 'Scheduled for ${fmt.format(announcement.scheduledAt!)}'
                        : 'Created ${fmt.format(announcement.createdAt)}',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, h:mm a');
    showDetailSheet(
      context,
      (ctx) => DetailSheetScaffold(
        avatarIcon: Icons.campaign_rounded,
        avatarGradient: AppColors.accentGradient(AppColors.brandDeep),
        title: announcement.title,
        subtitle: announcement.shortDescription,
        statusRow: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(color: AppColors.brandDeep, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              const Icon(Icons.campaign_rounded, color: AppColors.white, size: 18),
              const SizedBox(width: 8),
              NotificationStatusBadge(status: announcement.status),
              const Spacer(),
              Text('${announcement.views} views', style: const TextStyle(color: AppColors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        sections: [
          DetailSection(title: 'Details', items: [
            DetailRow(icon: Icons.short_text_rounded, label: 'Description', value: announcement.shortDescription),
            DetailRow(icon: Icons.person_outline, label: 'Created By', value: announcement.createdBy),
          ]),
          DetailSection(title: 'Audience', items: [
            DetailRow(icon: Icons.groups_outlined, label: 'Target', value: audienceLabel(announcement.audience)),
          ]),
          if (announcement.ctaLabel != null)
            DetailSection(title: 'Call to Action', items: [
              DetailRow(icon: Icons.touch_app_outlined, label: 'Button', value: announcement.ctaLabel!),
              DetailRow(icon: Icons.link_rounded, label: 'Action', value: openOnTapLabel(announcement.ctaTarget), iconColor: AppColors.positive),
            ]),
          DetailSection(title: 'Timeline', items: [
            DetailRow(icon: Icons.add_circle_outline, label: 'Created', value: fmt.format(announcement.createdAt)),
            if (announcement.scheduledAt != null)
              DetailRow(icon: Icons.schedule_outlined, label: 'Scheduled', value: fmt.format(announcement.scheduledAt!)),
            if (announcement.publishedAt != null)
              DetailRow(icon: Icons.publish_outlined, label: 'Published', value: fmt.format(announcement.publishedAt!)),
          ]),
        ],
      ),
    );
  }
}
