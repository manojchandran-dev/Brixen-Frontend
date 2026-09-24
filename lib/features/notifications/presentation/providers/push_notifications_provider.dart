import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/push_notifications_repository_impl.dart';
import '../../domain/entities/push_notification.dart';

final pushNotificationsProvider =
    AsyncNotifierProvider<PushNotificationsNotifier, List<PushNotification>>(
      PushNotificationsNotifier.new,
    );

class PushNotificationsNotifier extends AsyncNotifier<List<PushNotification>> {
  List<PushNotification> _all = [];

  @override
  Future<List<PushNotification>> build() async {
    _all = await ref.read(pushNotificationsRepositoryProvider).getAll();
    return _all;
  }

  /// Re-fetches with the given status/search filters applied server-side —
  /// call whenever either changes. Replaces the old approach of loading
  /// once and filtering the in-memory list, which only ever saw the first
  /// `limit` (100) notifications regardless of which status was selected.
  Future<void> reload({String? status, String? search}) async {
    state = const AsyncLoading<List<PushNotification>>().copyWithPrevious(
      state,
    );
    try {
      _all = await ref
          .read(pushNotificationsRepositoryProvider)
          .getAll(status: status, search: search);
      state = AsyncData(List.from(_all));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<PushNotification> create(PushNotification notification) async {
    final created = await ref
        .read(pushNotificationsRepositoryProvider)
        .create(notification);
    _all = [created, ..._all];
    state = AsyncData(List.from(_all));
    return created;
  }

  // Named `edit` (not `update`) — `AsyncNotifier` already defines a
  // built-in `update` with an incompatible signature.
  Future<PushNotification> edit(PushNotification notification) async {
    final updated = await ref
        .read(pushNotificationsRepositoryProvider)
        .update(notification);
    _replace(updated);
    return updated;
  }

  Future<void> delete(String id) async {
    await ref.read(pushNotificationsRepositoryProvider).delete(id);
    _all = _all.where((n) => n.id != id).toList();
    state = AsyncData(List.from(_all));
  }

  Future<PushNotification> duplicate(String id) async {
    final copy = await ref
        .read(pushNotificationsRepositoryProvider)
        .duplicate(id);
    _all = [copy, ..._all];
    state = AsyncData(List.from(_all));
    return copy;
  }

  Future<PushNotification> cancel(String id) async {
    final cancelled = await ref
        .read(pushNotificationsRepositoryProvider)
        .cancel(id);
    _replace(cancelled);
    return cancelled;
  }

  void _replace(PushNotification updated) {
    _all = _all.map((n) => n.id == updated.id ? updated : n).toList();
    state = AsyncData(List.from(_all));
  }
}
