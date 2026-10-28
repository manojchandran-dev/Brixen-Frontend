import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'skeleton.dart';

/// Renders an image from an `image_picker` `XFile.path`, or an already-
/// hosted URL (e.g. a product's saved `gallery_urls`). A real http(s)/blob
/// URL always goes through `Image.network`, regardless of platform — a
/// native app editing an existing record with a real hosted URL needs this
/// just as much as web does. Only an actual local filesystem path — which
/// can't exist on web at all — falls through to `Image.file`.
///
/// A hosted image shows a shimmer while it downloads and fades in; a small
/// one (a list thumbnail, both sides given and at most 160) asks Cloudinary
/// for a resized copy, so it arrives in a fraction of the time.
Widget pickedImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (kIsWeb ||
      path.startsWith('http://') ||
      path.startsWith('https://') ||
      path.startsWith('blob:')) {
    return Image.network(
      _thumbnail(path, width, height),
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, sync) => sync
          ? child
          : AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              child: child,
            ),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : Shimmer(
              child: SkeletonBox(
                width: width?.isFinite == true ? width : double.infinity,
                height: height?.isFinite == true ? height! : 160,
                radius: 0,
              ),
            ),
      errorBuilder: (context, _, _) => Container(
        width: width,
        height: height,
        color: AppColors.surfaceElevated,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined, color: AppColors.textHint),
      ),
    );
  }
  return Image.file(File(path), width: width, height: height, fit: fit);
}

/// A Cloudinary URL resized for a small box (3× for sharp screens);
/// anything else unchanged.
String _thumbnail(String url, double? width, double? height) {
  const marker = '/image/upload/';
  if (width == null ||
      height == null ||
      !width.isFinite ||
      !height.isFinite ||
      width > 160 ||
      height > 160 ||
      !url.contains('res.cloudinary.com') ||
      !url.contains(marker)) {
    return url;
  }
  final w = (width * 3).round(), h = (height * 3).round();
  return url.replaceFirst(
    marker,
    '${marker}c_fill,w_$w,h_$h,q_auto,f_auto/',
  );
}
