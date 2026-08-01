library;

/// Abstraction over on-device text recognition (OCR).

abstract interface class OcrGateway {
  /// Extracts the visible text from the image at [imagePath].
  ///
  /// Returns an empty string when nothing readable was found.
  Future<String> extractText(String imagePath);
}
