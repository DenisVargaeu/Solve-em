library;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../domain/repositories/ocr_gateway.dart';

/// On-device OCR backed by Google ML Kit.
///
/// Runs fully offline — text is extracted on the phone and only the extracted
/// text (plus the image, in AI mode) is ever sent to the AI provider.

class OcrService implements OcrGateway {
  @override
  Future<String> extractText(String imagePath) async {
    if (kIsWeb) {
      throw const UnsupportedPlatformException(
        'OCR is not available on the web build.',
      );
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(input);
      return result.text;
    } catch (e) {
      throw const OcrException();
    } finally {
      await recognizer.close();
    }
  }
}
