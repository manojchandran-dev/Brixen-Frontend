import 'package:flutter/material.dart';
import 'picked_image.dart';

/// Full-screen image viewer: swipe between [urls] (hosted links or picked
/// local files), pinch to zoom, ✕ (top-right) or back to close, "2 / 3"
/// counter when there's more than one.
void showImageViewer(
  BuildContext context,
  List<String> urls, {
  int initialIndex = 0,
}) {
  if (urls.isEmpty) return;
  showDialog(
    context: context,
    barrierColor: Colors.black,
    builder: (dCtx) => _ImageViewer(urls: urls, initialIndex: initialIndex),
  );
}

class _ImageViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _ImageViewer({required this.urls, required this.initialIndex});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  // Zoom of the photo on screen. Unzoomed, drags swipe between photos;
  // zoomed, they pan the photo (InteractiveViewer would otherwise swallow
  // every horizontal drag and block the swipe).
  final _zoom = TransformationController();
  bool _zoomed = false;

  void _onZoom() {
    final z = _zoom.value.getMaxScaleOnAxis() > 1.01;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void initState() {
    super.initState();
    _zoom.addListener(_onZoom);
  }

  @override
  void dispose() {
    _zoom.dispose();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: widget.urls.length,
            physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
            onPageChanged: (i) {
              _zoom.value = Matrix4.identity(); // next photo starts unzoomed
              setState(() => _index = i);
            },
            itemBuilder: (_, i) => InteractiveViewer(
              maxScale: 5,
              transformationController: i == _index ? _zoom : null,
              panEnabled: _zoomed,
              child: Center(
                child: pickedImage(widget.urls[i], fit: BoxFit.contain),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  if (widget.urls.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_index + 1} / ${widget.urls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Clear on any photo: white disc, dark ✕.
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: IconButton(
                      tooltip: 'Close',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.black87,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
