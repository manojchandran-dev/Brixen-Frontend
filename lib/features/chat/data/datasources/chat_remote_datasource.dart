import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/chat_conversation.dart';
import '../models/chat_message_model.dart';

final chatRemoteDatasourceProvider = Provider<ChatRemoteDatasource>((ref) {
  return ChatRemoteDatasource(ref.read(dioProvider));
});

class ChatRemoteDatasource {
  final Dio _dio;
  const ChatRemoteDatasource(this._dio);

  List _items(Response resp) {
    final data = resp.data['data'] ?? resp.data;
    return data is List ? data : (data['items'] ?? []) as List;
  }

  Future<List<ChatConversation>> conversations() async {
    try {
      final resp = await _dio.get(ApiEndpoints.chatConversations);
      return _items(resp).map((e) {
        final c = e as Map<String, dynamic>;
        final last = c['last_message'];
        return ChatConversation(
          companyId: c['company_id'].toString(),
          companyName: (c['company_name'] ?? '').toString(),
          messages: last is Map<String, dynamic> ? [chatMessageFromJson(last)] : const [],
        );
      }).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Oldest to newest. Latest 100 for now — `before=<id>` paging isn't wired
  /// into the UI yet.
  Future<List<ChatMessage>> messages(String companyId) async {
    try {
      final resp = await _dio.get(ApiEndpoints.chatMessages(companyId), queryParameters: {'limit': 100});
      return _items(resp).map((e) => chatMessageFromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> send(
    String companyId, {
    required MessageType type,
    String text = '',
    String? attachmentUrl,
    int durationMs = 0,
  }) async {
    try {
      await _dio.post(ApiEndpoints.chatMessages(companyId), data: {
        'type': type.name,
        if (text.isNotEmpty) 'text': text,
        'attachment_url': ?attachmentUrl,
        if (durationMs > 0) 'duration_ms': durationMs,
      });
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
