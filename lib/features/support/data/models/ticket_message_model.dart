import '../../domain/entities/ticket_message.dart';

class TicketMessageModel extends TicketMessage {
  const TicketMessageModel({
    required super.id,
    required super.senderName,
    required super.isSupportReply,
    required super.text,
    required super.sentAt,
  });

  factory TicketMessageModel.fromJson(Map<String, dynamic> json) =>
      TicketMessageModel(
        id: json['id'].toString(),
        senderName: (json['sender_name'] ?? '').toString(),
        isSupportReply: json['is_support_reply'] == true,
        text: (json['text'] ?? '').toString(),
        sentAt:
            DateTime.tryParse(json['sent_at']?.toString() ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_name': senderName,
    'is_support_reply': isSupportReply,
    'text': text,
    'sent_at': sentAt.toIso8601String(),
  };

  factory TicketMessageModel.fromEntity(TicketMessage m) => TicketMessageModel(
    id: m.id,
    senderName: m.senderName,
    isSupportReply: m.isSupportReply,
    text: m.text,
    sentAt: m.sentAt,
  );
}
