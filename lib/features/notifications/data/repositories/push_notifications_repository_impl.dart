import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/push_notification.dart';
import '../../domain/repositories/push_notifications_repository.dart';
import '../datasources/push_notifications_remote_datasource.dart';
import '../models/push_notification_model.dart';

final pushNotificationsRepositoryProvider =
    Provider<PushNotificationsRepository>((ref) {
      return PushNotificationsRepositoryImpl(
        ref.read(pushNotificationsRemoteDatasourceProvider),
      );
    });

class PushNotificationsRepositoryImpl implements PushNotificationsRepository {
  final PushNotificationsRemoteDatasource _ds;
  const PushNotificationsRepositoryImpl(this._ds);

  @override
  Future<List<PushNotification>> getAll({String? status, String? search}) =>
      _ds.getAll(status: status, search: search);

  @override
  Future<PushNotification> getById(String id) => _ds.getById(id);

  @override
  Future<PushNotification> create(PushNotification notification) =>
      _ds.create(PushNotificationModel.fromEntity(notification));

  @override
  Future<PushNotification> update(PushNotification notification) =>
      _ds.update(PushNotificationModel.fromEntity(notification));

  @override
  Future<void> delete(String id) => _ds.delete(id);

  @override
  Future<PushNotification> duplicate(String id) => _ds.duplicate(id);

  @override
  Future<PushNotification> cancel(String id) => _ds.cancel(id);
}
