import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/push_notification.dart';

/// One shared status pill covering both Push Notification and Announcement
/// status enums (they're the same `CommunicationStatus` type).
class NotificationStatusBadge extends StatelessWidget {
  final CommunicationStatus status;
  const NotificationStatusBadge({super.key, required this.status});

  static const _labels = {
    CommunicationStatus.draft: 'Draft',
    CommunicationStatus.scheduled: 'Scheduled',
    CommunicationStatus.sending: 'Sending',
    CommunicationStatus.sent: 'Sent',
    CommunicationStatus.published: 'Published',
    CommunicationStatus.failed: 'Failed',
    CommunicationStatus.cancelled: 'Cancelled',
  };

  /// The status colour — also used to tint the notification cards.
  static Color colorFor(CommunicationStatus s) => switch (s) {
    CommunicationStatus.draft => AppColors.brandLight,
    CommunicationStatus.scheduled => AppColors.accentGold,
    CommunicationStatus.sending => AppColors.brand,
    CommunicationStatus.sent => AppColors.positive,
    CommunicationStatus.published => AppColors.positive,
    CommunicationStatus.failed => AppColors.accentRose,
    CommunicationStatus.cancelled => AppColors.brandBlack,
  };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: AppColors.accentGradient(color)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _labels[status] ?? status.name,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
