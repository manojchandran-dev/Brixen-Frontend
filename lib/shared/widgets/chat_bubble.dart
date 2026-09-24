import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';

/// One chat bubble — the viewer's own messages align right and tinted,
/// received ones align left. [child] is the body (text, image, ...).
/// [media] trims the padding so images sit close to the bubble edge.
class ChatBubble extends StatelessWidget {
  final String senderName;
  final bool isMine;
  final DateTime sentAt;
  final Widget child;
  final bool media;
  const ChatBubble({
    super.key,
    required this.senderName,
    required this.isMine,
    required this.sentAt,
    required this.child,
    this.media = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: media
            ? const EdgeInsets.all(5)
            : const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          gradient: isMine
              ? const LinearGradient(
                  colors: [AppColors.brand, AppColors.brandDeep],
                )
              : null,
          color: isMine ? null : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          boxShadow: AppColors.shadows([
            BoxShadow(
              color: AppColors.shadowDark.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: isMine ? Colors.white : AppColors.ink),
          // Bubble is as wide as its widest line (name / body / time).
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Your own name is noise — only label the other side.
                if (!isMine)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      media ? 7 : 0,
                      media ? 3 : 0,
                      0,
                      3,
                    ),
                    child: Text(
                      senderName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                child,
                Padding(
                  padding: EdgeInsets.only(
                    top: 3,
                    right: media ? 6 : 0,
                    bottom: media ? 2 : 0,
                  ),
                  child: Text(
                    DateFormat('h:mm a').format(sentAt),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.75)
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Today" / "Yesterday" / "23 Sep 2026" pill between days.
class ChatDateDivider extends StatelessWidget {
  final DateTime date;
  const ChatDateDivider({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = DateUtils.dateOnly(
      now,
    ).difference(DateUtils.dateOnly(date)).inDays;
    final label = switch (days) {
      0 => 'Today',
      1 => 'Yesterday',
      _ => DateFormat(
        date.year == now.year ? 'd MMM' : 'd MMM yyyy',
      ).format(date),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
        ],
      ),
    );
  }
}
