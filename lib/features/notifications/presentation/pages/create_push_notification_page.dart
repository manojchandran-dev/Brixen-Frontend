import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../companies/presentation/providers/companies_provider.dart';
import '../../domain/entities/audience_target.dart';
import '../../domain/entities/push_notification.dart';
import '../providers/push_notifications_provider.dart';
import '../widgets/audience_selector.dart';
import '../widgets/character_counter.dart';
import '../widgets/notification_labels.dart';
import '../widgets/notification_preview.dart';
import '../widgets/schedule_section.dart';

const _titleMax = 60;
const _messageMax = 250;

final _titleValidator = FormBuilderValidators.compose<String>([
  FormBuilderValidators.required(errorText: 'Title is required'),
  FormBuilderValidators.maxLength(
    _titleMax,
    errorText: 'Keep it under $_titleMax characters',
  ),
]);

final _messageValidator = FormBuilderValidators.compose<String>([
  FormBuilderValidators.required(errorText: 'Message is required'),
  FormBuilderValidators.maxLength(
    _messageMax,
    errorText: 'Keep it under $_messageMax characters',
  ),
]);

final _routeValidator = FormBuilderValidators.compose<String>([
  FormBuilderValidators.required(errorText: 'Enter the page route to open'),
  FormBuilderValidators.match(
    RegExp(r'^/'),
    errorText: 'Must start with /, e.g. /billing/invoices',
  ),
]);

class CreatePushNotificationPage extends ConsumerStatefulWidget {
  final PushNotification? editNotification;
  const CreatePushNotificationPage({super.key, this.editNotification});

  @override
  ConsumerState<CreatePushNotificationPage> createState() =>
      _CreatePushNotificationPageState();
}

class _CreatePushNotificationPageState
    extends ConsumerState<CreatePushNotificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _routeCtrl = TextEditingController();

  AudienceTarget _audience = const AudienceTarget.allCompanies();
  NotificationPriority _priority = NotificationPriority.normal;
  OpenOnTapTarget _openOnTap = OpenOnTapTarget.none;

  bool _isScheduled = false;
  DateTime _scheduleDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduleTime = const TimeOfDay(hour: 9, minute: 0);

  bool _submitting = false;

  bool get _isEditing => widget.editNotification != null;

  @override
  void initState() {
    super.initState();
    final n = widget.editNotification;
    if (n != null) {
      _titleCtrl.text = n.title;
      _messageCtrl.text = n.message;
      _audience = n.audience;
      _priority = n.priority;
      _openOnTap = n.openOnTap;
      _routeCtrl.text = n.specificPageRoute ?? '';
      if (n.scheduledAt != null) {
        _isScheduled = true;
        _scheduleDate = n.scheduledAt!;
        _scheduleTime = TimeOfDay.fromDateTime(n.scheduledAt!);
      }
    }
    _titleCtrl.addListener(() => setState(() {}));
    _messageCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _routeCtrl.dispose();
    super.dispose();
  }

  DateTime get _scheduledAt => DateTime(
    _scheduleDate.year,
    _scheduleDate.month,
    _scheduleDate.day,
    _scheduleTime.hour,
    _scheduleTime.minute,
  );

  Future<void> _submit({required bool asDraft}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final companies = ref.read(companiesProvider).valueOrNull ?? const [];
    final recipientCount = _audience.estimatedRecipients(companies);

    if (!asDraft && !_isScheduled) {
      final ok = await showConfirmDialog(
        context,
        title: 'Send Notification',
        message:
            'Send notification to $recipientCount ${recipientCount == 1 ? 'company' : 'companies'}?',
        confirmLabel: 'Confirm & Send',
      );
      if (!ok) return;
    }

    setState(() => _submitting = true);
    try {
      final status = asDraft
          ? CommunicationStatus.draft
          : _isScheduled
          ? CommunicationStatus.scheduled
          : CommunicationStatus.sent;

      final notification = PushNotification(
        id: widget.editNotification?.id ?? '',
        title: _titleCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
        audience: _audience,
        priority: _priority,
        openOnTap: _openOnTap,
        specificPageRoute: _openOnTap == OpenOnTapTarget.specificPage
            ? _routeCtrl.text.trim()
            : null,
        status: status,
        scheduledAt: _isScheduled ? _scheduledAt : null,
        recipients: status == CommunicationStatus.sent
            ? recipientCount
            : (_isScheduled ? recipientCount : 0),
        createdAt: widget.editNotification?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await ref.read(pushNotificationsProvider.notifier).edit(notification);
      } else {
        await ref.read(pushNotificationsProvider.notifier).create(notification);
      }
      if (!mounted) return;
      context.pop();
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Notification' : 'Create Notification',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 760;
            final form = _buildForm(isWide: isWide);
            if (!isWide) return form;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: form),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 28, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Preview',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        NotificationPreview(
                          title: _titleCtrl.text,
                          message: _messageCtrl.text,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildActionBar(),
    );
  }

  Widget _buildForm({required bool isWide}) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _SectionCard(
            icon: Icons.edit_note_rounded,
            iconColor: AppColors.brand,
            title: 'Notification Details',
            child: Column(
              children: [
                BrixenTextField(
                  label: 'Notification Title *',
                  hint: 'Enter notification title',
                  controller: _titleCtrl,
                  validator: _titleValidator,
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
                CharacterCounter(
                  current: _titleCtrl.text.length,
                  max: _titleMax,
                ),
                const SizedBox(height: 12),
                BrixenTextField(
                  label: 'Message *',
                  hint: 'Enter your notification message...',
                  controller: _messageCtrl,
                  validator: _messageValidator,
                  maxLines: 4,
                  prefixIcon: const Icon(Icons.message_outlined),
                ),
                CharacterCounter(
                  current: _messageCtrl.text.length,
                  max: _messageMax,
                ),
                if (!isWide) ...[
                  const SizedBox(height: 14),
                  NotificationPreview(
                    title: _titleCtrl.text,
                    message: _messageCtrl.text,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.groups_rounded,
            iconColor: AppColors.positive,
            title: 'Audience',
            child: AudienceSelector(
              value: _audience,
              onChanged: (v) => setState(() => _audience = v),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.flag_rounded,
            iconColor: AppColors.brandDeep,
            title: 'Priority',
            child: Row(
              children: NotificationPriority.values.map((p) {
                final selected = _priority == p;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: p != NotificationPriority.values.last ? 8 : 0,
                    ),
                    child: _PriorityChip(
                      label: priorityLabel(p),
                      icon: _priorityIcon(p),
                      color: _priorityColor(p),
                      selected: selected,
                      onTap: () => setState(() => _priority = p),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.touch_app_outlined,
            iconColor: AppColors.brandLight,
            title: 'Open on Tap',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrixenDropdown<OpenOnTapTarget>(
                  hint: 'No Action',
                  value: _openOnTap,
                  items: OpenOnTapTarget.values,
                  labelOf: openOnTapLabel,
                  icon: Icons.touch_app_outlined,
                  onChanged: (v) =>
                      setState(() => _openOnTap = v ?? OpenOnTapTarget.none),
                ),
                if (_openOnTap == OpenOnTapTarget.specificPage) ...[
                  const SizedBox(height: 12),
                  BrixenTextField(
                    label: 'Page route *',
                    hint: 'e.g. /billing/invoices',
                    controller: _routeCtrl,
                    validator: _routeValidator,
                    prefixIcon: const Icon(Icons.link_rounded),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.schedule_rounded,
            iconColor: AppColors.brandBlack,
            title: 'Delivery',
            child: ScheduleSection(
              isScheduled: _isScheduled,
              onModeChanged: (v) => setState(() => _isScheduled = v),
              date: _scheduleDate,
              onDateChanged: (v) => setState(() => _scheduleDate = v),
              time: _scheduleTime,
              onTimeChanged: (v) => setState(() => _scheduleTime = v),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _priorityIcon(NotificationPriority p) {
    switch (p) {
      case NotificationPriority.normal:
        return Icons.notifications_none_rounded;
      case NotificationPriority.important:
        return Icons.priority_high_rounded;
      case NotificationPriority.urgent:
        return Icons.warning_amber_rounded;
    }
  }

  static Color _priorityColor(NotificationPriority p) {
    switch (p) {
      case NotificationPriority.normal:
        return AppColors.brand;
      case NotificationPriority.important:
        return AppColors.accentGold;
      case NotificationPriority.urgent:
        return AppColors.accentRose;
    }
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: BrixenButton(
              label: 'Draft',
              isOutlined: true,
              onPressed: _submitting ? null : () => _submit(asDraft: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: BrixenButton(
              label: 'Submit',
              isLoading: _submitting,
              onPressed: _submitting ? null : () => _submit(asDraft: false),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every form section lives in its own elevated card, headed by a small
/// coloured icon badge — the flat text-label sections this replaced made
/// the page read as one long undifferentiated list; a card boundary per
/// concern (details / audience / priority / tap action / delivery) makes
/// each step scannable on its own.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.highlightShadow(0.9),
            blurRadius: 6,
            offset: const Offset(-2, -2),
          ),
        ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.accentGradient(iconColor),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: AppColors.white),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _PriorityChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Theme.of(context).dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? color : cs.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
