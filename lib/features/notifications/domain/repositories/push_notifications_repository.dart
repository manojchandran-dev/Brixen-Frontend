import '../entities/push_notification.dart';

abstract class PushNotificationsRepository {
  Future<List<PushNotification>> getAll({String? status, String? search});
  Future<PushNotification> getById(String id);
  Future<PushNotification> create(PushNotification notification);
  Future<PushNotification> update(PushNotification notification);
  Future<void> delete(String id);
  Future<PushNotification> duplicate(String id);
  Future<PushNotification> cancel(String id);
}
