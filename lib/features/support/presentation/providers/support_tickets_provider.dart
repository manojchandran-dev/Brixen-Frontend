import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/support_tickets_repository_impl.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/ticket_message.dart';

final supportTicketsProvider =
    AsyncNotifierProvider<SupportTicketsNotifier, List<SupportTicket>>(
      SupportTicketsNotifier.new,
    );

/// The backend scopes the list by session (a company only ever gets its own
/// tickets; superAdmin gets all), so nothing is filtered here.
class SupportTicketsNotifier extends AsyncNotifier<List<SupportTicket>> {
  List<SupportTicket> _all = [];

  @override
  Future<List<SupportTicket>> build() async {
    _all = await ref.read(supportTicketsRepositoryProvider).getAll();
    return _all;
  }

  /// Re-fetches with the Support page's search and filters (server-side).
  /// Keeps the current list in the loading state so the page can decide
  /// how to show it.
  Future<void> reload({
    String? search,
    String? status,
    String? priority,
    String? category,
    String? companyId,
  }) async {
    state = const AsyncLoading<List<SupportTicket>>().copyWithPrevious(state);
    try {
      _all = await ref
          .read(supportTicketsRepositoryProvider)
          .getAll(
            search: search,
            status: status,
            priority: priority,
            category: category,
            companyId: companyId,
          );
      state = AsyncData(List.from(_all));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<SupportTicket> create(SupportTicket ticket) async {
    final created = await ref
        .read(supportTicketsRepositoryProvider)
        .create(ticket);
    _all = [created, ..._all];
    state = AsyncData(List.from(_all));
    return created;
  }

  /// Pulls the full ticket (with its messages) into the list — the list
  /// endpoint may not include them.
  Future<void> loadDetail(String id) async {
    _replace(await ref.read(supportTicketsRepositoryProvider).getById(id));
  }

  Future<SupportTicket> addMessage(
    String ticketId,
    TicketMessage message,
  ) async {
    final updated = await ref
        .read(supportTicketsRepositoryProvider)
        .addMessage(ticketId, message);
    _replace(updated);
    return updated;
  }

  Future<SupportTicket> updateStatus(
    String ticketId,
    TicketStatus status,
  ) async {
    final updated = await ref
        .read(supportTicketsRepositoryProvider)
        .updateStatus(ticketId, status);
    _replace(updated);
    return updated;
  }

  Future<SupportTicket> assign(String ticketId, String assignee) async {
    final updated = await ref
        .read(supportTicketsRepositoryProvider)
        .assign(ticketId, assignee);
    _replace(updated);
    return updated;
  }

  void _replace(SupportTicket updated) {
    final exists = _all.any((t) => t.id == updated.id);
    _all = exists
        ? _all.map((t) => t.id == updated.id ? updated : t).toList()
        : [updated, ..._all];
    state = AsyncData(List.from(_all));
  }
}
