import 'dart:async';
import 'dart:io' show Directory;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import '../../../../core/network/upload_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/action_sheet.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/chat_bubble.dart';
import '../../../../shared/widgets/picked_image.dart';
import '../../domain/entities/chat_conversation.dart';
import '../providers/chat_provider.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../widgets/voice_bubble.dart';

/// One company's conversation with support. [isRoot] = reached straight from
/// the drawer (company users), so it gets the drawer/hamburger; superAdmin
/// opens it from the list and gets a normal back arrow.
class ChatRoomPage extends ConsumerStatefulWidget {
  final String companyId;
  final String companyName;
  final bool isRoot;
  const ChatRoomPage({super.key, required this.companyId, required this.companyName, this.isRoot = false});

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();
  final _recordWatch = Stopwatch();
  Timer? _recordTicker;
  bool _sending = false;
  bool _recording = false;

  Timer? _poll;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() => setState(() {}));
    // No socket yet — refresh every 5s (previous messages stay on screen while it reloads).
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_sending) ref.invalidate(chatMessagesProvider(widget.companyId));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _recordTicker?.cancel();
    _recorder.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _snack(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString()), backgroundColor: AppColors.dangerFill),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        0, // list is reversed — 0 is the newest message
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// One send path for text, image and voice messages.
  Future<void> _post({
    String text = '',
    MessageType type = MessageType.text,
    String? url,
    int durationMs = 0,
  }) async {
    setState(() => _sending = true);
    try {
      await ref.read(chatMessagesProvider(widget.companyId).notifier).send(
            type: type,
            text: text,
            attachmentUrl: url,
            durationMs: durationMs,
          );
      _scrollToBottom();
    } catch (e) {
      _snack(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    await _post(text: text);
  }

  void _openAttachSheet() {
    showActionSheet(
      context,
      title: 'Attach Image',
      items: [
        ActionSheetItem(
          icon: Icons.photo_library_outlined,
          label: 'Gallery',
          color: AppColors.brand,
          onTap: () => _pickImage(ImageSource.gallery),
        ),
        ActionSheetItem(
          icon: Icons.camera_alt_outlined,
          label: 'Camera',
          color: AppColors.positive,
          onTap: () => _pickImage(ImageSource.camera),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    setState(() => _sending = true);
    try {
      final url = await ref.read(uploadServiceProvider).uploadImage(file, folder: 'support');
      await _post(type: MessageType.image, url: url);
    } catch (e) {
      _snack(e);
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        _snack('Microphone permission is needed to record a voice message');
        return;
      }
      final path = kIsWeb ? '' : '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      // Browsers can't encode AAC; opus is what MediaRecorder actually produces.
      await _recorder.start(
        RecordConfig(encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc),
        path: path,
      );
      _recordWatch
        ..reset()
        ..start();
      _recordTicker = Timer.periodic(const Duration(milliseconds: 250), (_) => setState(() {}));
      setState(() => _recording = true);
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _stopRecording({required bool send}) async {
    _recordTicker?.cancel();
    _recordWatch.stop();
    final durationMs = _recordWatch.elapsedMilliseconds;
    setState(() => _recording = false);
    if (!send) {
      await _recorder.cancel();
      return;
    }
    final path = await _recorder.stop();
    if (path == null || durationMs < 500) return;
    setState(() => _sending = true);
    try {
      final url = await ref.read(uploadServiceProvider).uploadAudio(XFile(path), folder: 'support');
      await _post(type: MessageType.voice, url: url, durationMs: durationMs);
    } catch (e) {
      _snack(e);
      if (mounted) setState(() => _sending = false);
    }
  }

  String _mmss(int ms) {
    final s = ms ~/ 1000;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Widget _circleButton(IconData icon, VoidCallback? onTap, {bool loading = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.brand, AppColors.brandDeep]),
          shape: BoxShape.circle,
        ),
        child: loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildInputBar() {
    final cs = Theme.of(context).colorScheme;
    final hasText = _textCtrl.text.trim().isNotEmpty;

    final Widget row = _recording
        ? Row(
            children: [
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary),
                onPressed: () => _stopRecording(send: false),
              ),
              Icon(Icons.fiber_manual_record_rounded, size: 14, color: AppColors.brandBlack),
              const SizedBox(width: 6),
              Text(
                _mmss(_recordWatch.elapsedMilliseconds),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
              const Spacer(),
              _circleButton(Icons.send_rounded, () => _stopRecording(send: true)),
            ],
          )
        : Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file_rounded, color: AppColors.textSecondary),
                onPressed: _sending ? null : _openAttachSheet,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _textCtrl,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'Message', border: InputBorder.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              hasText
                  ? _circleButton(Icons.send_rounded, _sending ? null : _sendText, loading: _sending)
                  : _circleButton(Icons.mic_rounded, _sending ? null : _startRecording, loading: _sending),
            ],
          );

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: AppColors.shadows([
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4)),
          ]),
        ),
        child: row,
      ),
    );
  }

  Widget _content(ChatMessage m) {
    switch (m.type) {
      case MessageType.image:
        return GestureDetector(
          onTap: () => _openImage(m.attachmentUrl!),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: pickedImage(m.attachmentUrl!, width: 230, height: 230),
          ),
        );
      case MessageType.voice:
        return VoiceBubble(
          url: m.attachmentUrl!,
          durationMs: m.durationMs,
          onDark: _isMine(m),
        );
      case MessageType.text:
        return Text(m.text, style: const TextStyle(fontSize: 14.5, height: 1.3));
    }
  }

  bool _isMine(ChatMessage m) => m.isSupport == Session.isSuperAdmin;

  /// Full-screen photo: pinch-zoom, close and download.
  void _openImage(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (dCtx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(child: pickedImage(url, fit: BoxFit.contain)),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(dCtx).pop(),
                    ),
                    const Spacer(),
                    if (url.startsWith('http'))
                      IconButton.filledTonal(
                        tooltip: 'Download',
                        icon: const Icon(Icons.download_rounded),
                        onPressed: () async {
                          if (!await downloadAttachment(url)) _snack('Could not open image for download');
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final messagesAsync = ref.watch(chatMessagesProvider(widget.companyId));
    final messages = messagesAsync.valueOrNull ?? const <ChatMessage>[];
    if (messages.length > _lastCount) _scrollToBottom();
    _lastCount = messages.length;

    return Scaffold(
      drawer: widget.isRoot ? const AppDrawer() : null,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          Session.isSuperAdmin ? widget.companyName : 'Chat with Support',
          style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: messagesAsync.isLoading
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : Text(
                            messagesAsync.hasError ? messagesAsync.error.toString() : 'No messages yet — say hello',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                  )
                // Reversed so the chat opens at the latest message and stays
                // pinned there as new ones arrive.
                : ListView.builder(
                    controller: _scrollCtrl,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final idx = messages.length - 1 - i;
                      final m = messages[idx];
                      final newDay = idx == 0 ||
                          !DateUtils.isSameDay(messages[idx - 1].sentAt, m.sentAt);
                      final bubble = ChatBubble(
                        senderName: m.senderName,
                        isMine: _isMine(m),
                        sentAt: m.sentAt,
                        media: m.type == MessageType.image,
                        child: _content(m),
                      );
                      if (!newDay) return bubble;
                      return Column(
                        children: [ChatDateDivider(date: m.sentAt), bubble],
                      );
                    },
                  ),
          ),
          // Sending needs create on the Chatbot module; without it the
          // conversation is read-only.
          if (ref.watch(moduleAccessProvider('Chatbot')).create)
            _buildInputBar()
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'You have view-only access to chat',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textHint, fontSize: 12.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
