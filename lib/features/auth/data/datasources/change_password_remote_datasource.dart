import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

final changePasswordRemoteDatasourceProvider =
    Provider<ChangePasswordRemoteDatasource>((ref) {
      return ChangePasswordRemoteDatasource(ref.read(dioProvider));
    });

/// Logged-in "Change Password" (More → Profile) — needs the Bearer token,
/// unlike [PasswordResetRemoteDatasource]'s pre-login OTP flow, so this
/// goes through the shared authenticated [dioProvider] instead of a
/// standalone client.
class ChangePasswordRemoteDatasource {
  final Dio _dio;
  const ChangePasswordRemoteDatasource(this._dio);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
