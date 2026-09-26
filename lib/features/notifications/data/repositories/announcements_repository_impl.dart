import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcements_repository.dart';
import '../datasources/announcements_remote_datasource.dart';
import '../models/announcement_model.dart';

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((
  ref,
) {
  return AnnouncementsRepositoryImpl(
    ref.read(announcementsRemoteDatasourceProvider),
  );
});

class AnnouncementsRepositoryImpl implements AnnouncementsRepository {
  final AnnouncementsRemoteDatasource _ds;
  const AnnouncementsRepositoryImpl(this._ds);

  @override
  Future<List<Announcement>> getAll() => _ds.getAll();

  @override
  Future<Announcement> create(Announcement announcement) =>
      _ds.create(AnnouncementModel.fromEntity(announcement));

  @override
  Future<Announcement> update(Announcement announcement) =>
      _ds.update(AnnouncementModel.fromEntity(announcement));

  @override
  Future<void> delete(String id) => _ds.delete(id);

  @override
  Future<Announcement> duplicate(String id) => _ds.duplicate(id);

  @override
  Future<Announcement> unpublish(String id) => _ds.unpublish(id);
}
