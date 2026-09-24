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
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../../shared/widgets/search_field.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../domain/entities/support_ticket.dart';
import '../providers/support_tickets_provider.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../widgets/ticket_labels.dart';
import '../widgets/ticket_status_badge.dart';

/// ONE shared route for every role — branches its body on `Session.role`,
/// same pattern as `DashboardHomePage` (`dashboard_home_page.dart`) rather
/// than three separate superAdmin/companyAdmin/employee routes.
class SupportTicketsPage extends ConsumerStatefulWidget {
  const SupportTicketsPage({super.key});

  @override
  ConsumerState<SupportTicketsPage> createState() => _SupportTicketsPageState();
}

class _SupportTicketsPageState extends ConsumerState<SupportTicketsPage> {
  final _searchCtrl = TextEditingController();
  TicketStatus? _statusFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSuperAdmin = Session.isSuperAdmin;
    final ticketsAsync = ref.watch(supportTicketsProvider);

    return Scaffold(
      extendBody: true,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(activeIndex: 3),
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
        title: Text(
          isSuperAdmin ? 'Support Tickets' : 'Support',
          style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (isSuperAdmin)
            DeletedItemsButton(
              title: 'Deleted tickets',
              listPath: ApiEndpoints.supportTickets,
              restorePath: (t) => '${ApiEndpoints.supportTickets}/${t['id']}/restore',
              labelOf: (t) => (t['subject'] ?? '').toString(),
              subtitleOf: (t) => t['company_name'] as String?,
              onRestored: () => ref.invalidate(supportTicketsProvider),
            ),
          if (!isSuperAdmin &&
              ref.watch(moduleAccessProvider('Support Ticket')).create)
            GestureDetector(
              onTap: () => context.push(AppRouter.createTicket),
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
              hintText: 'Search tickets...',
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (isSuperAdmin)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(label: 'All', selected: _statusFilter == null, onTap: () => setState(() => _statusFilter = null)),
                  for (final s in TicketStatus.values)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: statusLabel(s),
                        selected: _statusFilter == s,
                        onTap: () => setState(() => _statusFilter = s),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ticketsAsync.when(
              loading: () => const SkeletonListView(),
              error: (e, _) => ErrorCard(error: e, onRetry: () => ref.invalidate(supportTicketsProvider)),
              data: (list) {
                final query = _searchCtrl.text.trim().toLowerCase();
                final filtered = list.where((t) {
                  final matchesQuery = query.isEmpty ||
                      t.subject.toLowerCase().contains(query) ||
                      t.companyName.toLowerCase().contains(query);
                  final matchesStatus = _statusFilter == null || t.status == _statusFilter;
                  return matchesQuery && matchesStatus;
                }).toList()
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.support_agent_rounded, size: 64, color: AppColors.brand.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          list.isEmpty ? 'No support tickets yet' : 'No results',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                        if (list.isEmpty && !isSuperAdmin) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Need help? Raise a ticket and our team will reply.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _TicketCard(index: i, ticket: filtered[i], showCompany: isSuperAdmin),
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
  const _FilterChip({required this.label, required this.selected, required this.onTap});

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

Color _priorityColor(TicketPriority p) => switch (p) {
      TicketPriority.low => AppColors.positive,
      TicketPriority.medium => AppColors.brand,
      TicketPriority.high => AppColors.brandDeep,
      TicketPriority.urgent => AppColors.brandBlack,
    };

class _Tag extends StatelessWidget {
  final String label;
  final Color? dot;
  const _Tag({required this.label, this.dot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final bool showCompany;
  final int index;
  const _TicketCard({required this.index, required this.ticket, required this.showCompany});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM, h:mm a');
    final lastMessage = ticket.messages.isNotEmpty ? ticket.messages.last : null;
    return GestureDetector(
      onTap: () => context.push(AppRouter.ticketDetail, extra: ticket),
      child: RichCardShell.tinted(index: index, child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCompany) ...[
                InitialsAvatar(seed: ticket.companyName, size: 44),
                const SizedBox(width: 12),
              ],
              Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.25),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  TicketStatusBadge(status: ticket.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                showCompany
                    ? '${ticket.companyName} · ${fmt.format(ticket.updatedAt)}'
                    : fmt.format(ticket.updatedAt),
                style: TextStyle(fontSize: 11.5, color: AppColors.textHint),
              ),
              const SizedBox(height: 10),
              Text(
                lastMessage?.text ?? ticket.description,
                style: TextStyle(fontSize: 13, height: 1.35, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Tag(label: categoryLabel(ticket.category)),
                  const SizedBox(width: 8),
                  _Tag(label: priorityLabel(ticket.priority), dot: _priorityColor(ticket.priority)),
                  const Spacer(),
                  Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    ticket.assignedTo ?? 'Unassigned',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textHint),
                  ),
                ],
              ),
            ],
          )),
            ],
          ),
        ),
      ),
    );
  }
}
