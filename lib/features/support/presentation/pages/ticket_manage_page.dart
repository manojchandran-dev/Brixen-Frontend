import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../../shared/widgets/initials_avatar.dart';
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
    Future.microtask(() => ref.read(supportTicketsProvider.notifier).loadDetail(widget.ticket.id).catchError((_) {}));
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
      if (_status != ticket.status) await notifier.updateStatus(ticket.id, _status);
      if (note.isNotEmpty) {
        await notifier.addMessage(
          ticket.id,
          TicketMessage(id: '', senderName: 'Support Team', isSupportReply: true, text: note, sentAt: DateTime.now()),
        );
        _noteCtrl.clear();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.dangerFill),
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
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Assignee name'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(dCtx).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dCtx).pop(ctrl.text.trim()), child: const Text('Assign')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(supportTicketsProvider.notifier).assign(ticket.id, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ticket = _current(ref.watch(supportTicketsProvider).valueOrNull);
    final fmt = DateFormat('dd MMM, h:mm a');
    final changed = _status != ticket.status || _noteCtrl.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Manage Ticket', style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.shadows([
                BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6)),
              ]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InitialsAvatar(seed: ticket.companyName, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ticket.companyName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          Text('Raised by ${ticket.raisedBy}', style: TextStyle(fontSize: 11.5, color: AppColors.textHint)),
                        ],
                      ),
                    ),
                    TicketStatusBadge(status: ticket.status),
                  ],
                ),
                const SizedBox(height: 14),
                Text(ticket.subject, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.25)),
                const SizedBox(height: 6),
                Text(ticket.description, style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _Chip(categoryLabel(ticket.category)),
                    _Chip('${priorityLabel(ticket.priority)} priority'),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _assign(ticket),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textHint),
                      const SizedBox(width: 6),
                      Text(
                        ticket.assignedTo == null ? 'Unassigned — tap to assign' : 'Assigned to ${ticket.assignedTo}',
                        style: TextStyle(fontSize: 12.5, color: AppColors.brand, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in TicketStatus.values)
                GestureDetector(
                  onTap: () => setState(() => _status = s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _status == s ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _status == s ? cs.primary : Theme.of(context).dividerColor,
                        width: _status == s ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      statusLabel(s),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _status == s ? FontWeight.w700 : FontWeight.w500,
                        color: _status == s ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          BrixenTextField(
            label: 'Add a note',
            hint: 'e.g. Fixed in the latest update — please retry',
            controller: _noteCtrl,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          Text('The company can see notes on their ticket.', style: TextStyle(fontSize: 11.5, color: AppColors.textHint)),
          const SizedBox(height: 16),
          BrixenButton(
            label: 'Update Ticket',
            isLoading: _saving,
            onPressed: _saving || !changed ? null : () => _save(ticket),
          ),
          const SizedBox(height: 26),
          Text('Activity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 10),
          for (final m in ticket.messages.reversed)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: m.isSupportReply ? AppColors.brand.withValues(alpha: 0.1) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        m.isSupportReply ? 'Note · ${m.senderName}' : m.senderName,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: m.isSupportReply ? AppColors.brand : AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Text(fmt.format(m.sentAt), style: TextStyle(fontSize: 10.5, color: AppColors.textHint)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(m.text, style: TextStyle(fontSize: 13, color: AppColors.ink)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
    );
  }
}
