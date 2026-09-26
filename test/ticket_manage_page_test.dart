import 'package:brixen/features/support/data/repositories/support_tickets_repository_impl.dart';
import 'package:brixen/features/support/domain/entities/support_ticket.dart';
import 'package:brixen/features/support/domain/entities/ticket_message.dart';
import 'package:brixen/features/support/domain/repositories/support_tickets_repository.dart';
import 'package:brixen/features/support/presentation/pages/ticket_manage_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _ticket = SupportTicket(
  id: 't1',
  subject: 'Need GST report export',
  description: 'Please add a monthly GST summary export to Excel.',
  category: TicketCategory.featureRequest,
  status: TicketStatus.inProgress,
  companyId: '30',
  companyName: 'MJP tex',
  raisedBy: 'Manoj',
  messages: [
    TicketMessage(id: 'm1', senderName: 'Manoj', isSupportReply: false, text: 'Please add a monthly GST summary export to Excel.', sentAt: DateTime(2026, 9, 24, 9, 15)),
    TicketMessage(id: 'm2', senderName: 'Support', isSupportReply: true, text: 'Working on it.', sentAt: DateTime(2026, 9, 24, 10)),
  ],
  createdAt: DateTime(2026, 9, 24),
  updatedAt: DateTime(2026, 9, 24),
);

class _Repo implements SupportTicketsRepository {
  @override
  Future<List<SupportTicket>> getAll({String? search, String? status, String? priority, String? category, String? companyId}) async => [_ticket];
  @override
  Future<SupportTicket> getById(String id) async => _ticket;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  // Renders the redesigned screen (ticket card, status choices, timeline)
  // with real data, so layout errors fail here rather than on a device.
  testWidgets('manage ticket page renders ticket, statuses and activity', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [supportTicketsRepositoryProvider.overrideWithValue(_Repo())],
      child: MaterialApp(home: TicketManagePage(ticket: _ticket)),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Need GST report export'), findsOneWidget);
    expect(find.text('Feature Request'), findsOneWidget);
    expect(find.text('Assign'), findsOneWidget);
    expect(find.text('Resolved'), findsOneWidget); // a status choice
    // The timeline is below the fold — scroll to it.
    await tester.scrollUntilVisible(
      find.text('Working on it.'),
      200,
      scrollable: find.byType(Scrollable).first, // the page list, not the note field
    );
    expect(find.text('Working on it.'), findsOneWidget); // timeline entry
    expect(tester.takeException(), isNull);
  });
}
