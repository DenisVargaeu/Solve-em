library;

import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

import '../constants/app_constants.dart';

/// Helpers for preparing photos before they are sent to the AI API.

abstract final class ImageUtils {
  ImageUtils._();

  /// Decodes, downscales and re-encodes an image file so it is small enough
  /// to embed in an API request body.
  ///
  /// * Keeps the image aspect ratio.
  /// * Caps the longest side at [AppConstants.maxImageDimension].
  /// * Re-encodes as JPEG (quality 82) which is ideal for OCR and vision.
  /// * Returns `null` when the file could not be read (e.g. on web).
  static Future<File?> prepareForUpload(String sourcePath) async {
    try {
      final bytes = await File(sourcePath).readAsBytes();
      var decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final longest = decoded.width > decoded.height
          ? decoded.width
          : decoded.height;
      if (longest > AppConstants.maxImageDimension) {
        decoded = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height
              ? AppConstants.maxImageDimension
              : null,
          height: decoded.width < decoded.height
              ? AppConstants.maxImageDimension
              : null,
          interpolation: img.Interpolation.linear,
        );
      }

      final outPath =
          '${sourcePath.substring(0, sourcePath.lastIndexOf('.'))}_prepared.jpg';
      final outFile = File(outPath);
      await outFile.writeAsBytes(
        img.encodeJpg(decoded, quality: 82),
        flush: true,
      );
      return outFile;
    } catch (_) {
      return null;
    }
  }

  /// Encodes an image file as a base64 data-URL (`data:image/jpeg;base64,...`)
  /// ready to be sent to a vision model.
  static Future<String> toDataUrl(String path) async {
    final bytes = await File(path).readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  /// Shortens long file paths for display purposes.
  static String displayName(String path) {
    final segments = path.split('/');
    return segments.isNotEmpty ? segments.last : path;
  }
}
