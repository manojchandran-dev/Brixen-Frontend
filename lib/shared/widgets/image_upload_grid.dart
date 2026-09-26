import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/upload_service.dart';
import '../../core/theme/app_colors.dart';
import 'picked_image.dart';

/// One slot: a freshly-picked local photo mid-upload (or failed), or an
/// already-hosted URL. Only [url]s are ever saved — [file] is just the
/// local preview while it uploads.
class _Photo {
  final XFile? file;
  String? url;
  bool uploading;
  String? error;

  _Photo.local(XFile this.file) : uploading = true;
  _Photo.remote(String this.url) : file = null, uploading = false;

  String get previewPath => file?.path ?? url!;
}

/// State for an [ImageUploadGrid], owned by the form so it can read the
/// uploaded [urls] and block submitting while [busy] or [hasFailed].
class ImageUploadController extends ChangeNotifier {
  final int max;
  final List<_Photo> _photos;

  ImageUploadController({
    required this.max,
    List<String> initialUrls = const [],
  }) : _photos = [for (final u in initialUrls.take(max)) _Photo.remote(u)];

  /// Hosted URLs of every successfully uploaded photo, in order.
  List<String> get urls => [
    for (final p in _photos)
      if (p.url != null) p.url!,
  ];

  bool get busy => _photos.any((p) => p.uploading);
  bool get hasFailed => _photos.any((p) => p.error != null);
  bool get isFull => _photos.length >= max;

  void _changed() => notifyListeners();

  /// Replaces the photos with already-hosted [urls] (e.g. after loading a
  /// record to edit).
  void setUrls(List<String> urls) {
    _photos
      ..clear()
      ..addAll([for (final u in urls.take(max)) _Photo.remote(u)]);
    notifyListeners();
  }
}

/// Pick (camera or gallery) → upload right away via `POST /uploads` → show
/// a tile with a spinner, retry on failure, and a remove button. Up to
/// [ImageUploadController.max] photos; with max 1 the single tile is the
/// picker itself (e.g. a logo).
class ImageUploadGrid extends ConsumerWidget {
  final ImageUploadController controller;
  final String title;
  final String? subtitle;

  /// Upload folder on the server, e.g. 'companies'.
  final String folder;

  const ImageUploadGrid({
    super.key,
    required this.controller,
    required this.title,
    required this.folder,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final photos = controller._photos;
        final showAdd = !controller.isFull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length + (showAdd ? 1 : 0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (_, i) => i == photos.length
                  ? _AddTile(onTap: () => _chooseSource(context, ref))
                  : _PhotoTile(
                      photo: photos[i],
                      onRemove: () {
                        photos.removeAt(i);
                        controller._changed();
                      },
                      onRetry: () => _upload(ref, photos[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _chooseSource(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add $title',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _pick(context, ref, ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _pick(context, ref, ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final remaining = controller.max - controller._photos.length;
    if (remaining <= 0) return;
    final List<XFile> files;
    if (source == ImageSource.camera || remaining == 1) {
      final f = await picker.pickImage(source: source, imageQuality: 85);
      files = f == null ? const [] : [f];
    } else {
      files = await picker.pickMultiImage(imageQuality: 85);
    }
    if (files.isEmpty) return;
    final accepted = files.take(remaining).map(_Photo.local).toList();
    controller._photos.addAll(accepted);
    controller._changed();
    for (final p in accepted) {
      _upload(ref, p);
    }
    if (files.length > accepted.length && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only ${controller.max} photos allowed — added the first $remaining.',
          ),
          backgroundColor: AppColors.dangerFill,
        ),
      );
    }
  }

  Future<void> _upload(WidgetRef ref, _Photo photo) async {
    photo
      ..uploading = true
      ..error = null;
    controller._changed();
    try {
      photo.url = await ref
          .read(uploadServiceProvider)
          .uploadImage(photo.file!, folder: folder);
    } catch (e) {
      photo.error = e.toString();
    }
    photo.uploading = false;
    // The tile may have been removed while uploading.
    if (controller._photos.contains(photo)) controller._changed();
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isDark ? AppColors.silver : AppColors.brand).withValues(
              alpha: 0.3,
            ),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.add_a_photo_outlined,
          size: 26,
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final _Photo photo;
  final VoidCallback onRemove;
  final VoidCallback onRetry;
  const _PhotoTile({
    required this.photo,
    required this.onRemove,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: photo.error != null ? 0.4 : 1,
            child: pickedImage(
              photo.previewPath,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        if (photo.uploading)
          const Positioned.fill(
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (photo.error != null)
          Positioned.fill(
            child: GestureDetector(
              onTap: onRetry,
              child: const Center(
                child: Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isDark ? AppColors.silver : AppColors.brand,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
