import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/push_notification.dart';
import '../models/push_notification_model.dart';

final pushNotificationsRemoteDatasourceProvider =
    Provider<PushNotificationsRemoteDatasource>((ref) {
      return PushNotificationsRemoteDatasource(ref.read(dioProvider));
    });

class PushNotificationsRemoteDatasource {
  final Dio _dio;
  const PushNotificationsRemoteDatasource(this._dio);

  PushNotificationModel _one(Response resp) => PushNotificationModel.fromJson(
    (resp.data['data'] ?? resp.data) as Map<String, dynamic>,
  );

  /// Only what the API accepts — recipients/delivered/failed are computed
  /// server-side and never sent. `status` is draft | scheduled | sent, where
  /// sent means "send now".
  Map<String, dynamic> _body(PushNotificationModel n) => {
    'title': n.title,
    'message': n.message,
    'audience': n.audience.toJson(),
    'priority': n.priority.name,
    'open_on_tap': n.openOnTap.name,
    if (n.openOnTap == OpenOnTapTarget.specificPage)
      'specific_page_route': n.specificPageRoute,
    'status': n.status.name,
    if (n.scheduledAt != null)
      'scheduled_at': n.scheduledAt!.toUtc().toIso8601String(),
  };

  /// Fresh single-record fetch — the list response is a lighter payload
  /// than this (e.g. no per-company delivery breakdown), so View/Edit
  /// always re-fetch by id instead of trusting whatever the list already
  /// had in memory.
  Future<PushNotificationModel> getById(String id) async {
    try {
      return _one(await _dio.get(ApiEndpoints.pushNotificationById(id)));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// [status] must be one of `CommunicationStatus`'s own names (draft,
  /// scheduled, sending, sent, failed, cancelled) — the server 400s on
  /// anything else, including `published` (not a push status). Omit it
  /// for "All". Filtering server-side (rather than fetching everything
  /// and filtering client-side) is what keeps this correct past `limit`'s
  /// 100 — a client-side filter over just the first page would silently
  /// miss older notifications of the selected status.
  Future<List<PushNotificationModel>> getAll({
    String? status,
    String? search,
  }) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.pushNotifications,
        queryParameters: {
          'page': 1,
          'limit': 100,
          if (status != null && status.isNotEmpty) 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final data = resp.data['data'] ?? resp.data;
      final list = data is List ? data : (data['items'] ?? []);
      return (list as List)
          .map((e) => PushNotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<PushNotificationModel> create(PushNotificationModel n) async {
    try {
      return _one(
        await _dio.post(ApiEndpoints.pushNotifications, data: _body(n)),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// 409 if it's no longer draft/scheduled.
  Future<PushNotificationModel> update(PushNotificationModel n) async {
    try {
      return _one(
        await _dio.put(ApiEndpoints.pushNotificationById(n.id), data: _body(n)),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete(ApiEndpoints.pushNotificationById(id));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<PushNotificationModel> duplicate(String id) async {
    try {
      return _one(await _dio.post(ApiEndpoints.pushNotificationDuplicate(id)));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// 409 unless it's still scheduled.
  Future<PushNotificationModel> cancel(String id) async {
    try {
      return _one(await _dio.post(ApiEndpoints.pushNotificationCancel(id)));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
