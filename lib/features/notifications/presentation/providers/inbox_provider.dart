import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

/// One push in a company user's inbox (`GET /notifications/push/inbox`).
class InboxItem {
  final String id;
  final String title;
  final String message;
  final String priority;
  final DateTime? sentAt;
  final bool read;

  /// `open_on_tap` / `specific_page_route` — where tapping it goes, same as
  /// tapping the push itself.
  final Map<String, dynamic> target;

  const InboxItem({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.sentAt,
    required this.read,
    required this.target,
  });

  factory InboxItem.fromJson(Map<String, dynamic> j) => InboxItem(
    id: '${j['id']}',
    title: '${j['title'] ?? ''}',
    message: '${j['message'] ?? ''}',
    priority: '${j['priority'] ?? 'normal'}',
    sentAt: DateTime.tryParse('${j['sent_at']}')?.toLocal(),
    read: j['read'] == true,
    target: {
      'open_on_tap': j['open_on_tap'],
      'specific_page_route': j['specific_page_route'],
    },
  );
}

/// The newest inbox page plus the company's total unread count (the bell).
class Inbox {
  final List<InboxItem> items;
  final int unread;
  const Inbox(this.items, this.unread);
}

/// Company users only (superadmin gets 403 — their bell is elsewhere).
/// ponytail: first 50 only, add paging when an inbox outgrows that.
final inboxProvider = FutureProvider.autoDispose<Inbox>((ref) async {
  try {
    final resp = await ref
        .read(dioProvider)
        .get(ApiEndpoints.pushInbox, queryParameters: {'page': 1, 'limit': 50});
    final data = resp.data['data'] ?? resp.data;
    final items = [
      for (final j in (data['items'] as List? ?? const []))
        InboxItem.fromJson(Map<String, dynamic>.from(j as Map)),
    ];
    final unread =
        (data['meta']?['unread'] as num?)?.toInt() ??
        items.where((i) => !i.read).length;
    return Inbox(items, unread);
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

/// Opening an item marks it read — the same call as tapping the push.
Future<void> markInboxItemRead(WidgetRef ref, String id) async {
  try {
    await ref.read(dioProvider).post(ApiEndpoints.pushOpened(id));
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}

Future<void> markAllInboxRead(WidgetRef ref) async {
  try {
    await ref.read(dioProvider).post(ApiEndpoints.pushInboxReadAll);
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}
