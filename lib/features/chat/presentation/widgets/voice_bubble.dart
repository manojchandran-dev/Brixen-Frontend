import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';

/// Hands [url] to the browser / OS, which offers the save/download.
// ponytail: no in-app save — add `gal` (gallery) or path_provider+dio if a
// silent in-app download is needed.
Future<bool> downloadAttachment(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Play/pause + progress for a voice note. Each bubble owns its own player.
class VoiceBubble extends StatefulWidget {
  final String url;
  final int durationMs;

  /// White controls, for use on the dark (own-message) bubble.
  final bool onDark;
  const VoiceBubble({
    super.key,
    required this.url,
    required this.durationMs,
    this.onDark = false,
  });

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  final _player = AudioPlayer();
  final _subs = <StreamSubscription>[];
  PlayerState _state = PlayerState.stopped;
  Duration _pos = Duration.zero;
  late Duration _total = Duration(milliseconds: widget.durationMs);

  bool get _playing => _state == PlayerState.playing;

  @override
  void initState() {
    super.initState();
    _subs.addAll([
      _player.onPlayerStateChanged.listen(
        (s) => mounted ? setState(() => _state = s) : null,
      ),
      _player.onPositionChanged.listen(
        (p) => mounted ? setState(() => _pos = p) : null,
      ),
      _player.onDurationChanged.listen(
        (d) => mounted && d > Duration.zero ? setState(() => _total = d) : null,
      ),
      _player.onPlayerComplete.listen(
        (_) => mounted ? setState(() => _pos = Duration.zero) : null,
      ),
    ]);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) return _player.pause();
    if (_state == PlayerState.paused) return _player.resume();
    final remote =
        widget.url.startsWith('http') || widget.url.startsWith('blob:');
    await _player.play(
      remote ? UrlSource(widget.url) : DeviceFileSource(widget.url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total.inMilliseconds == 0
        ? 0.0
        : (_pos.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);
    final fg = widget.onDark ? Colors.white : AppColors.brand;
    final remote = widget.url.startsWith('http');
    final s = (_playing || _pos > Duration.zero ? _pos : _total).inSeconds;
    return SizedBox(
      width: 220,
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: widget.onDark ? AppColors.brand : Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              color: fg,
              backgroundColor: fg.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 11,
              color: widget.onDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          if (remote)
            IconButton(
              tooltip: 'Download',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.download_rounded, size: 18, color: fg),
              onPressed: () => downloadAttachment(widget.url),
            ),
        ],
      ),
    );
  }
}
