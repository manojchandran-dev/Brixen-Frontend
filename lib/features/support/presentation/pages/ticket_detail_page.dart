import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/support_ticket.dart';
import '../providers/support_tickets_provider.dart';
import '../widgets/ticket_labels.dart';
import '../widgets/ticket_status_badge.dart';

/// The company's read-only view of a ticket: what they raised, its current
/// status, and any notes support has added. No replying here — live
/// conversation is the Chatbot module.
class TicketDetailPage extends ConsumerStatefulWidget {
  final SupportTicket ticket;
  const TicketDetailPage({super.key, required this.ticket});

  @override
  ConsumerState<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends ConsumerState<TicketDetailPage> {
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
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final cs = Theme.of(context).colorScheme;
    // The list provider is the source of truth once loaded; falls back to the
    // ticket passed via `extra`. Not firstWhere(orElse:) — the list is really a
    // list of SupportTicketModel, so an orElse returning SupportTicket fails.
    final t =
        ref
            .watch(supportTicketsProvider)
            .valueOrNull
            ?.where((x) => x.id == ticket.id)
            .firstOrNull ??
        ticket;
    final notes = t.messages
        .where((m) => m.isSupportReply)
        .toList()
        .reversed
        .toList();
    final fmt = DateFormat('dd MMM yyyy, h:mm a');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Ticket',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
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
                BoxShadow(
                  color: AppColors.shadowDark.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.subject,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TicketStatusBadge(status: t.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  t.description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    _Chip(categoryLabel(t.category)),
                    _Chip('${priorityLabel(t.priority)} priority'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Raised by ${t.raisedBy} · ${fmt.format(t.createdAt)}',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textHint),
                ),
                if (t.assignedTo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Assigned to ${t.assignedTo}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Updates from Support',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          if (notes.isEmpty)
            Text(
              'No updates yet — we\'ll add notes here as we work on it.',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            )
          else
            for (final m in notes)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fmt.format(m.sentAt),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.text,
                      style: TextStyle(fontSize: 13, color: AppColors.ink),
                    ),
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
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
