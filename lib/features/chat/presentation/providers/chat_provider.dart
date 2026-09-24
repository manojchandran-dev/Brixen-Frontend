import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_conversation.dart';

/// superAdmin's list of every company's conversation.
final chatConversationsProvider = FutureProvider<List<ChatConversation>>(
  (ref) => ref.read(chatRepositoryProvider).conversations(),
);

/// One company's messages. The pages re-`invalidate` this on a timer to pick
/// up new messages (polling, until the backend offers a socket).
final chatMessagesProvider = AsyncNotifierProvider.family<ChatMessagesNotifier, List<ChatMessage>, String>(
  ChatMessagesNotifier.new,
);

class ChatMessagesNotifier extends FamilyAsyncNotifier<List<ChatMessage>, String> {
  @override
  Future<List<ChatMessage>> build(String companyId) => ref.read(chatRepositoryProvider).messages(companyId);

  Future<void> send({
    required MessageType type,
    String text = '',
    String? attachmentUrl,
    int durationMs = 0,
  }) async {
    final repo = ref.read(chatRepositoryProvider);
    await repo.send(arg, type: type, text: text, attachmentUrl: attachmentUrl, durationMs: durationMs);
    state = AsyncData(await repo.messages(arg));
  }
}
