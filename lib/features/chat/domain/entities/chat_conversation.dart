enum MessageType { text, image, voice }

class ChatMessage {
  final String id;
  final String senderName;
  /// true = the support (superAdmin) side; false = the company side.
  final bool isSupport;
  final String text;
  final DateTime sentAt;
  final MessageType type;
  /// Image URL (uploaded) or voice-note path/blob URL. Voice isn't uploaded —
  /// no audio upload endpoint exists yet, so it only lives for this session.
  final String? attachmentUrl;
  final int durationMs;

  const ChatMessage({
    required this.id,
    required this.senderName,
    required this.isSupport,
    this.text = '',
    required this.sentAt,
    this.type = MessageType.text,
    this.attachmentUrl,
    this.durationMs = 0,
  });

  /// One-line summary for list previews.
  String get preview => switch (type) {
        MessageType.image => 'Photo',
        MessageType.voice => 'Voice message',
        MessageType.text => text,
      };
}

/// One conversation per company with the Brixen support team.
class ChatConversation {
  final String companyId;
  final String companyName;
  final List<ChatMessage> messages;

  const ChatConversation({
    required this.companyId,
    required this.companyName,
    this.messages = const [],
  });

  ChatMessage? get last => messages.isEmpty ? null : messages.last;
  DateTime? get updatedAt => last?.sentAt;
}
