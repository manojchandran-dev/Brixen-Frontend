import '../entities/announcement.dart';

abstract class AnnouncementsRepository {
  Future<List<Announcement>> getAll();
  Future<Announcement> create(Announcement announcement);
  Future<Announcement> update(Announcement announcement);
  Future<void> delete(String id);
  Future<Announcement> duplicate(String id);
  Future<Announcement> unpublish(String id);
}
