import '../entities/chat_conversation.dart';

abstract class ChatRepository {
  /// superAdmin only — every company's conversation with its last message.
  Future<List<ChatConversation>> conversations();
  Future<List<ChatMessage>> messages(String companyId);
  Future<void> send(
    String companyId, {
    required MessageType type,
    String text = '',
    String? attachmentUrl,
    int durationMs = 0,
  });
}
