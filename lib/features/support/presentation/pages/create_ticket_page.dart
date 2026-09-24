import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../domain/entities/support_ticket.dart';
import '../providers/support_tickets_provider.dart';
import '../widgets/ticket_labels.dart';

/// companyAdmin/employee only — superAdmin responds to tickets, it doesn't
/// raise them.
class CreateTicketPage extends ConsumerStatefulWidget {
  const CreateTicketPage({super.key});

  @override
  ConsumerState<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends ConsumerState<CreateTicketPage> {
  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  TicketCategory _category = TicketCategory.technical;
  TicketPriority _priority = TicketPriority.medium;
  bool _submitting = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subjectCtrl.text.trim().isEmpty || _descriptionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject and description are required'), backgroundColor: AppColors.dangerFill),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final ticket = SupportTicket(
        id: '',
        subject: _subjectCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        category: _category,
        priority: _priority,
        companyId: Session.companyId ?? '',
        companyName: Session.companyName ?? '',
        raisedBy: Session.ownerName ?? Session.email ?? 'Unknown',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ref.read(supportTicketsProvider.notifier).create(ticket);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.dangerFill),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text('New Ticket', style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            BrixenTextField(
              label: 'Subject *',
              hint: 'Briefly describe the issue',
              controller: _subjectCtrl,
            ),
            const SizedBox(height: 16),
            BrixenTextField(
              label: 'Description *',
              hint: 'Give as much detail as you can...',
              controller: _descriptionCtrl,
              maxLines: 6,
            ),
            const SizedBox(height: 16),
            BrixenDropdown<TicketCategory>(
              hint: 'Category',
              value: _category,
              items: TicketCategory.values,
              labelOf: categoryLabel,
              icon: Icons.category_outlined,
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 16),
            Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 10),
            Row(
              children: TicketPriority.values.map((p) {
                final selected = _priority == p;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: p != TicketPriority.values.last ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? cs.primary : Theme.of(context).dividerColor, width: selected ? 1.5 : 1),
                        ),
                        child: Text(
                          priorityLabel(p),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            BrixenButton(
              label: 'Submit Ticket',
              isLoading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
