import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/push_notification.dart' show OpenOnTapTarget;
import '../models/announcement_model.dart';

final announcementsRemoteDatasourceProvider =
    Provider<AnnouncementsRemoteDatasource>((ref) {
      return AnnouncementsRemoteDatasource(ref.read(dioProvider));
    });

class AnnouncementsRemoteDatasource {
  final Dio _dio;
  const AnnouncementsRemoteDatasource(this._dio);

  AnnouncementModel _one(Response resp) => AnnouncementModel.fromJson(
    (resp.data['data'] ?? resp.data) as Map<String, dynamic>,
  );

  /// `status` is draft | scheduled | published. `content` is the Quill Delta
  /// JSON string, sent as-is.
  Map<String, dynamic> _body(AnnouncementModel a) => {
    'title': a.title,
    if (a.shortDescription.isNotEmpty) 'short_description': a.shortDescription,
    'content': a.content,
    'banner_url': ?a.bannerUrl,
    'audience': a.audience.toJson(),
    'cta_label': ?a.ctaLabel,
    'cta_target': a.ctaTarget.name,
    if (a.ctaTarget == OpenOnTapTarget.specificPage)
      'specific_page_route': a.specificPageRoute,
    'status': a.status.name,
    if (a.scheduledAt != null)
      'scheduled_at': a.scheduledAt!.toUtc().toIso8601String(),
  };

  Future<List<AnnouncementModel>> getAll() async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.announcements,
        queryParameters: {'page': 1, 'limit': 100},
      );
      final data = resp.data['data'] ?? resp.data;
      final list = data is List ? data : (data['items'] ?? []);
      return (list as List)
          .map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AnnouncementModel> create(AnnouncementModel a) async {
    try {
      return _one(await _dio.post(ApiEndpoints.announcements, data: _body(a)));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AnnouncementModel> update(AnnouncementModel a) async {
    try {
      return _one(
        await _dio.put(ApiEndpoints.announcementById(a.id), data: _body(a)),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete(ApiEndpoints.announcementById(id));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AnnouncementModel> duplicate(String id) async {
    try {
      return _one(await _dio.post(ApiEndpoints.announcementDuplicate(id)));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// 409 unless it's published or scheduled.
  Future<AnnouncementModel> unpublish(String id) async {
    try {
      return _one(await _dio.post(ApiEndpoints.announcementUnpublish(id)));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
