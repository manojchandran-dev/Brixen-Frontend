import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/ticket_message.dart';
import '../../domain/repositories/support_tickets_repository.dart';
import '../datasources/support_tickets_remote_datasource.dart';
import '../models/support_ticket_model.dart';

final supportTicketsRepositoryProvider = Provider<SupportTicketsRepository>((ref) {
  return SupportTicketsRepositoryImpl(ref.read(supportTicketsRemoteDatasourceProvider));
});

class SupportTicketsRepositoryImpl implements SupportTicketsRepository {
  final SupportTicketsRemoteDatasource _ds;
  const SupportTicketsRepositoryImpl(this._ds);

  @override
  Future<List<SupportTicket>> getAll() => _ds.getAll();

  @override
  Future<SupportTicket> getById(String id) => _ds.getById(id);

  @override
  Future<SupportTicket> create(SupportTicket ticket) => _ds.create(SupportTicketModel.fromEntity(ticket));

  @override
  Future<SupportTicket> addMessage(String ticketId, TicketMessage message) => _ds.addMessage(ticketId, message.text);

  @override
  Future<SupportTicket> updateStatus(String ticketId, TicketStatus status) => _ds.updateStatus(ticketId, status.name);

  @override
  Future<SupportTicket> assign(String ticketId, String assignee) => _ds.assign(ticketId, assignee);
}
