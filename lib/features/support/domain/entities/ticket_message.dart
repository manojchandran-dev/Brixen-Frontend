class TicketMessage {
  final String id;
  final String senderName;
  /// true = a reply from the superAdmin/support side; false = the company
  /// (companyAdmin/employee) side — drives which side a chat bubble aligns
  /// to in `ticket_detail_page.dart`.
  final bool isSupportReply;
  final String text;
  final DateTime sentAt;

  const TicketMessage({
    required this.id,
    required this.senderName,
    required this.isSupportReply,
    required this.text,
    required this.sentAt,
  });
}
