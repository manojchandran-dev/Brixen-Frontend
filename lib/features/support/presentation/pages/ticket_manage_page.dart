import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../../../shared/widgets/module_title.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/ticket_message.dart';
import '../providers/support_tickets_provider.dart';
import '../widgets/ticket_labels.dart';
import '../widgets/ticket_status_badge.dart';

/// superAdmin's view of a ticket: change its status, assign it and add notes
/// — not a chat. A note is stored as a support-side message, so the company
/// sees it in their own ticket thread.
class TicketManagePage extends ConsumerStatefulWidget {
  final SupportTicket ticket;
  const TicketManagePage({super.key, required this.ticket});

  @override
  ConsumerState<TicketManagePage> createState() => _TicketManagePageState();
}

class _TicketManagePageState extends ConsumerState<TicketManagePage> {
  final _noteCtrl = TextEditingController();
  late TicketStatus _status = widget.ticket.status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // The list may not carry messages — pull the full ticket in on open.
    Future.microtask(
      () => ref
          .read(supportTicketsProvider.notifier)
          .loadDetail(widget.ticket.id)
          .catchError((_) {}),
    );
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  // The list provider is the source of truth once loaded; falls back to the
  // ticket passed via `extra`. Not firstWhere(orElse:) — the list is really a
  // list of SupportTicketModel, so an orElse returning SupportTicket fails.
  SupportTicket _current(List<SupportTicket>? list) =>
      list?.where((t) => t.id == widget.ticket.id).firstOrNull ?? widget.ticket;

  Future<void> _save(SupportTicket ticket) async {
    final note = _noteCtrl.text.trim();
    setState(() => _saving = true);
    try {
      final notifier = ref.read(supportTicketsProvider.notifier);
      if (_status != ticket.status) {
        await notifier.updateStatus(ticket.id, _status);
      }
      if (note.isNotEmpty) {
        await notifier.addMessage(
          ticket.id,
          TicketMessage(
            id: '',
            senderName: 'Support Team',
            isSupportReply: true,
            text: note,
            sentAt: DateTime.now(),
          ),
        );
        _noteCtrl.clear();
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ticket updated')));
      }
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

  Future<void> _assign(SupportTicket ticket) async {
    final ctrl = TextEditingController(text: ticket.assignedTo ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: Theme.of(dCtx).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Assign Ticket'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Assignee name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(ctrl.text.trim()),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(supportTicketsProvider.notifier).assign(ticket.id, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _current(ref.watch(supportTicketsProvider).valueOrNull);
    final fmt = DateFormat('dd MMM, h:mm a');
    final changed =
        _status != ticket.status || _noteCtrl.text.trim().isNotEmpty;
    const accent = AppColors.brand;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: ModuleTitle(
          title: 'Manage Ticket',
          subtitle: ticket.companyName,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── The ticket ──
          RichCardShell(
            accentColor: accent,
            backgroundColor: Color.lerp(
              AppColors.surface,
              accent,
              AppColors.cardTintBlend(accent),
            ),
            backgroundGradient: AppColors.cardTintGradient(accent),
            edgeColor: accent,
            showAccentBar: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InitialsAvatar(
                        seed: ticket.companyName,
                        size: 44,
                        color: accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.companyName,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Raised by ${ticket.raisedBy}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.ink.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TicketStatusBadge(status: ticket.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ticket.subject,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: -0.2,
                      color: AppColors.ink,
                    ),
                  ),
                  if (ticket.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      ticket.description.trim(),
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: AppColors.ink.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // Category · priority · opened — one info strip.
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _InfoCell(
                          icon: Icons.category_outlined,
                          label: 'Category',
                          value: categoryLabel(ticket.category),
                        ),
                        _InfoCell(
                          icon: Icons.flag_rounded,
                          iconColor: priorityColor(ticket.priority),
                          label: 'Priority',
                          value: priorityLabel(ticket.priority),
                        ),
                        _InfoCell(
                          icon: Icons.schedule_rounded,
                          label: 'Opened',
                          value: DateFormat('dd MMM').format(ticket.createdAt),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Assignee, with an explicit action.
                  Row(
                    children: [
                      Icon(
                        ticket.assignedTo == null
                            ? Icons.person_add_alt_1_outlined
                            : Icons.person_rounded,
                        size: 18,
                        color: AppColors.ink.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ticket.assignedTo == null
                              ? 'Not assigned yet'
                              : 'Assigned to ${ticket.assignedTo}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.brand,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _assign(ticket),
                        icon: Icon(
                          ticket.assignedTo == null
                              ? Icons.add_rounded
                              : Icons.edit_outlined,
                          size: 16,
                        ),
                        label: Text(
                          ticket.assignedTo == null ? 'Assign' : 'Change',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Update: status + note + button, one card ──
          _SectionCard(
            title: 'Update ticket',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in TicketStatus.values)
                      _StatusChoice(
                        label: statusLabel(s),
                        color: TicketStatusBadge.colorFor(s),
                        selected: _status == s,
                        onTap: () => setState(() => _status = s),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                BrixenTextField(
                  label: 'Add a note',
                  hint: 'e.g. Fixed in the latest update — please retry',
                  controller: _noteCtrl,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 13,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'The company can see notes on their ticket.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                BrixenButton(
                  label: 'Update Ticket',
                  isLoading: _saving,
                  onPressed: _saving || !changed ? null : () => _save(ticket),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Activity timeline ──
          _SectionCard(
            title: 'Activity',
            trailing: '${ticket.messages.length}',
            child: ticket.messages.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No activity yet',
                      style: TextStyle(fontSize: 13, color: AppColors.textHint),
                    ),
                  )
                : Column(
                    children: [
                      for (final (i, m) in ticket.messages.reversed.indexed)
                        _TimelineEntry(
                          message: m,
                          time: fmt.format(m.sentAt),
                          isLast: i == ticket.messages.length - 1,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// White rounded card with a small heading (and optional count pill).
class _SectionCard extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;
  const _SectionCard({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              if (trailing != null) ...[
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
                    trailing!,
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// One figure in the ticket's info strip.
class _InfoCell extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  const _InfoCell({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: iconColor ?? AppColors.brand),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

/// A status option: colour dot + label; filled with the status colour when
/// selected.
class _StatusChoice extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _StatusChoice({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: selected ? 1 : 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_rounded : Icons.circle,
              size: selected ? 14 : 8,
              color: selected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One activity item: a dot on the timeline line and a message bubble —
/// support notes tinted, company messages plain.
class _TimelineEntry extends StatelessWidget {
  final TicketMessage message;
  final String time;
  final bool isLast;
  const _TimelineEntry({
    required this.message,
    required this.time,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final support = message.isSupportReply;
    final color = support ? AppColors.brand : AppColors.textSecondary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: support
                    ? AppColors.brand.withValues(alpha: 0.08)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        support
                            ? Icons.support_agent_rounded
                            : Icons.person_outline_rounded,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          support
                              ? 'Note · ${message.senderName}'
                              : message.senderName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
