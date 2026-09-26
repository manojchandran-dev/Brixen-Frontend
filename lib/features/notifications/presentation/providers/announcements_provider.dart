import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/announcements_repository_impl.dart';
import '../../domain/entities/announcement.dart';

final announcementsProvider =
    AsyncNotifierProvider<AnnouncementsNotifier, List<Announcement>>(
      AnnouncementsNotifier.new,
    );

class AnnouncementsNotifier extends AsyncNotifier<List<Announcement>> {
  List<Announcement> _all = [];

  @override
  Future<List<Announcement>> build() async {
    _all = await ref.read(announcementsRepositoryProvider).getAll();
    return _all;
  }

  Future<Announcement> create(Announcement announcement) async {
    final created = await ref
        .read(announcementsRepositoryProvider)
        .create(announcement);
    _all = [created, ..._all];
    state = AsyncData(List.from(_all));
    return created;
  }

  // Named `edit` (not `update`) — `AsyncNotifier` already defines a
  // built-in `update` with an incompatible signature.
  Future<Announcement> edit(Announcement announcement) async {
    final updated = await ref
        .read(announcementsRepositoryProvider)
        .update(announcement);
    _replace(updated);
    return updated;
  }

  Future<void> delete(String id) async {
    await ref.read(announcementsRepositoryProvider).delete(id);
    _all = _all.where((a) => a.id != id).toList();
    state = AsyncData(List.from(_all));
  }

  Future<Announcement> duplicate(String id) async {
    final copy = await ref.read(announcementsRepositoryProvider).duplicate(id);
    _all = [copy, ..._all];
    state = AsyncData(List.from(_all));
    return copy;
  }

  Future<Announcement> unpublish(String id) async {
    final updated = await ref
        .read(announcementsRepositoryProvider)
        .unpublish(id);
    _replace(updated);
    return updated;
  }

  void _replace(Announcement updated) {
    _all = _all.map((a) => a.id == updated.id ? updated : a).toList();
    state = AsyncData(List.from(_all));
  }
}
