import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.read(chatRemoteDatasourceProvider));
});

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDatasource _ds;
  const ChatRepositoryImpl(this._ds);

  @override
  Future<List<ChatConversation>> conversations() => _ds.conversations();

  @override
  Future<List<ChatMessage>> messages(String companyId) => _ds.messages(companyId);

  @override
  Future<void> send(
    String companyId, {
    required MessageType type,
    String text = '',
    String? attachmentUrl,
    int durationMs = 0,
  }) =>
      _ds.send(companyId, type: type, text: text, attachmentUrl: attachmentUrl, durationMs: durationMs);
}
