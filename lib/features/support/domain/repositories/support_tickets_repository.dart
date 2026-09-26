import '../entities/support_ticket.dart';
import '../entities/ticket_message.dart';

abstract class SupportTicketsRepository {
  Future<List<SupportTicket>> getAll({
    String? search,
    String? status,
    String? priority,
    String? category,
    String? companyId,
  });
  Future<SupportTicket> getById(String id);
  Future<SupportTicket> create(SupportTicket ticket);
  Future<SupportTicket> addMessage(String ticketId, TicketMessage message);
  Future<SupportTicket> updateStatus(String ticketId, TicketStatus status);
  Future<SupportTicket> assign(String ticketId, String assignee);
}
