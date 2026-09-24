import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/support_ticket.dart';
import 'ticket_labels.dart';

/// Same shape as the Notifications module's `NotificationStatusBadge`, for
/// `TicketStatus` instead of `CommunicationStatus`.
class TicketStatusBadge extends StatelessWidget {
  final TicketStatus status;
  const TicketStatusBadge({super.key, required this.status});

  Color _colorFor(TicketStatus s) => switch (s) {
        TicketStatus.open => AppColors.accentGold,
        TicketStatus.pending => AppColors.brandDeep,
        TicketStatus.inProgress => AppColors.brand,
        TicketStatus.resolved => AppColors.positive,
        TicketStatus.closed => AppColors.brandBlack,
      };

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: AppColors.accentGradient(color)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusLabel(status),
        style: const TextStyle(color: AppColors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
