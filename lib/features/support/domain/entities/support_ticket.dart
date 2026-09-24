import 'ticket_message.dart';

enum TicketCategory { technical, billing, featureRequest, bug, other }

enum TicketPriority { low, medium, high, urgent }

enum TicketStatus { open, pending, inProgress, resolved, closed }

class SupportTicket {
  final String id;
  final String subject;
  final String description;
  final TicketCategory category;
  final TicketPriority priority;
  final TicketStatus status;
  final String companyId;
  final String companyName;
  final String raisedBy;
  final String? assignedTo;
  final List<TicketMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    this.category = TicketCategory.other,
    this.priority = TicketPriority.medium,
    this.status = TicketStatus.open,
    required this.companyId,
    required this.companyName,
    required this.raisedBy,
    this.assignedTo,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  SupportTicket copyWith({
    TicketStatus? status,
    String? assignedTo,
    List<TicketMessage>? messages,
    DateTime? updatedAt,
  }) {
    return SupportTicket(
      id: id,
      subject: subject,
      description: description,
      category: category,
      priority: priority,
      status: status ?? this.status,
      companyId: companyId,
      companyName: companyName,
      raisedBy: raisedBy,
      assignedTo: assignedTo ?? this.assignedTo,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
