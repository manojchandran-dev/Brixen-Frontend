import '../../domain/entities/support_ticket.dart';

String categoryLabel(TicketCategory c) => switch (c) {
      TicketCategory.technical => 'Technical',
      TicketCategory.billing => 'Billing',
      TicketCategory.featureRequest => 'Feature Request',
      TicketCategory.bug => 'Bug',
      TicketCategory.other => 'Other',
    };

String priorityLabel(TicketPriority p) => switch (p) {
      TicketPriority.low => 'Low',
      TicketPriority.medium => 'Medium',
      TicketPriority.high => 'High',
      TicketPriority.urgent => 'Urgent',
    };

String statusLabel(TicketStatus s) => switch (s) {
      TicketStatus.open => 'Open',
      TicketStatus.pending => 'Pending',
      TicketStatus.inProgress => 'In Progress',
      TicketStatus.resolved => 'Resolved',
      TicketStatus.closed => 'Closed',
    };
