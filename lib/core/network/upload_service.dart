import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(ref.read(dioProvider));
});

/// `POST /api/v1/uploads` — Cloudinary-backed image upload. Takes one image
/// at a time and returns its hosted URL; there's no batch variant, so
/// callers uploading several images (e.g. a product gallery) fire one
/// request per image and track each independently.
class UploadService {
  final Dio _dio;
  const UploadService(this._dio);

  /// [folder] groups the image server-side — one of products, companies,
  /// employees, customers, sales, expenses (falls back to "misc" otherwise).
  Future<String> uploadImage(
    XFile file, {
    required String folder,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'folder': folder,
        'file': MultipartFile.fromBytes(bytes, filename: file.name),
      });
      final resp = await _dio.post(
        ApiEndpoints.uploads,
        data: formData,
        onSendProgress: onProgress,
      );
      final data = resp.data['data'] as Map<String, dynamic>;
      return data['url'] as String;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
