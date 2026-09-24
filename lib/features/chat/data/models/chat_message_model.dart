import '../../domain/entities/chat_conversation.dart';

/// Tolerant of missing keys: the conversations list only carries a
/// `last_message` with type/text/sent_at, while the messages endpoint
/// returns the full shape.
ChatMessage chatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
      id: json['id']?.toString() ?? '',
      senderName: (json['sender_name'] ?? '').toString(),
      isSupport: json['is_support'] == true,
      text: (json['text'] ?? '').toString(),
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '') ?? DateTime.now(),
      type: MessageType.values.firstWhere((t) => t.name == json['type'], orElse: () => MessageType.text),
      attachmentUrl: json['attachment_url'] as String?,
      durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
    );
