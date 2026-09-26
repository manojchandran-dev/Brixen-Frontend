import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(ref.read(dioProvider));
});

/// `POST /api/v1/uploads` — Cloudinary-backed upload. Takes one file at a time
/// and returns its hosted URL; there's no batch variant, so callers uploading
/// several files (e.g. a product gallery) fire one request per file.
class UploadService {
  final Dio _dio;
  const UploadService(this._dio);

  /// [folder] groups the file server-side — one of products, companies,
  /// employees, customers, sales, expenses, support (falls back to "misc").
  Future<String> uploadImage(
    XFile file, {
    required String folder,
    void Function(int sent, int total)? onProgress,
  }) async {
    return _upload(
      file.name,
      await file.readAsBytes(),
      folder,
      null,
      onProgress,
    );
  }

  /// A recorded voice note. Browsers record opus/webm, mobile records AAC/m4a;
  /// the multipart filename and content type must say which so the backend
  /// accepts it as audio.
  Future<String> uploadAudio(XFile file, {required String folder}) async {
    final name = kIsWeb ? 'voice.webm' : 'voice.m4a';
    final mime = kIsWeb ? 'audio/webm' : 'audio/mp4';
    return _upload(name, await file.readAsBytes(), folder, mime, null);
  }

  Future<String> _upload(
    String filename,
    List<int> bytes,
    String folder,
    String? mime,
    void Function(int sent, int total)? onProgress,
  ) async {
    try {
      final formData = FormData.fromMap({
        'folder': folder,
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: mime == null ? null : DioMediaType.parse(mime),
        ),
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
