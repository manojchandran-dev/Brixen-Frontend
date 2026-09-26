import '../../domain/entities/support_ticket.dart';
import 'ticket_message_model.dart';

/// `fromJson`/`toJson` are shaped like the real future
/// `POST /api/v1/support/tickets` payload would be, even though the mock
/// datasource never serializes over the wire yet — same rationale as the
/// Notifications models.
class SupportTicketModel extends SupportTicket {
  const SupportTicketModel({
    required super.id,
    required super.subject,
    required super.description,
    super.category,
    super.priority,
    super.status,
    required super.companyId,
    required super.companyName,
    required super.raisedBy,
    super.assignedTo,
    super.messages,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'].toString(),
      subject: (json['subject'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: TicketCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => TicketCategory.other,
      ),
      priority: TicketPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TicketPriority.medium,
      ),
      status: TicketStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TicketStatus.open,
      ),
      companyId: (json['company_id'] ?? '').toString(),
      companyName: (json['company_name'] ?? '').toString(),
      raisedBy: (json['raised_by'] ?? '').toString(),
      assignedTo: json['assigned_to'] as String?,
      messages: (json['messages'] as List? ?? [])
          .map((e) => TicketMessageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    'description': description,
    'category': category.name,
    'priority': priority.name,
    'status': status.name,
    'company_id': companyId,
    'company_name': companyName,
    'raised_by': raisedBy,
    'assigned_to': assignedTo,
    'messages': messages
        .map((m) => TicketMessageModel.fromEntity(m).toJson())
        .toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory SupportTicketModel.fromEntity(SupportTicket t) => SupportTicketModel(
    id: t.id,
    subject: t.subject,
    description: t.description,
    category: t.category,
    priority: t.priority,
    status: t.status,
    companyId: t.companyId,
    companyName: t.companyName,
    raisedBy: t.raisedBy,
    assignedTo: t.assignedTo,
    messages: t.messages,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
  );
}
