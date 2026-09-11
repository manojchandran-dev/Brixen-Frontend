import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Renders an image from an `image_picker` `XFile.path`, or an already-
/// hosted URL (e.g. a product's saved `gallery_urls`). A real http(s)/blob
/// URL always goes through `Image.network`, regardless of platform — a
/// native app editing an existing record with a real hosted URL needs this
/// just as much as web does. Only an actual local filesystem path — which
/// can't exist on web at all — falls through to `Image.file`.
Widget pickedImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (kIsWeb || path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:')) {
    return Image.network(path, width: width, height: height, fit: fit);
  }
  return Image.file(File(path), width: width, height: height, fit: fit);
}
