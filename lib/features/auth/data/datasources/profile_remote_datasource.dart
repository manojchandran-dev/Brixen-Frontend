import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/profile_model.dart';

final profileRemoteDatasourceProvider = Provider<ProfileRemoteDatasource>((
  ref,
) {
  return ProfileRemoteDatasource(ref.read(dioProvider));
});

/// Live `GET`/`PUT /api/v1/auth/me` — the "Profile" screen's own data used
/// to just read whatever [Session] cached at login; this fetches the
/// current record instead (and lets company/superadmin accounts edit it).
final profileProvider = FutureProvider<ProfileModel>((ref) {
  return ref.read(profileRemoteDatasourceProvider).getProfile();
});

class ProfileRemoteDatasource {
  final Dio _dio;
  const ProfileRemoteDatasource(this._dio);

  ProfileModel _profile(Response resp) {
    final data = resp.data['data'] ?? resp.data;
    return ProfileModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ProfileModel> getProfile() async {
    try {
      return _profile(await _dio.get(ApiEndpoints.me));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// [fields] — company: any subset of `owner_name`/`phone`/
  /// `secondary_email`/`website`. superAdmin: `email`.
  Future<ProfileModel> updateProfile(Map<String, dynamic> fields) async {
    try {
      return _profile(await _dio.put(ApiEndpoints.me, data: fields));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
