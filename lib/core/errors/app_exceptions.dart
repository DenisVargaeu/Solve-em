library;

/// Typed exceptions used across the app.
///
/// The presentation layer catches these (via a single `catch` and a
/// [AppException.message] lookup) and shows a friendly message, while the
/// underlying cause is preserved for debugging.

/// Base class for every application exception.
class AppException implements Exception {
  const AppException(this.message, {this.cause, this.code});

  /// Human readable message safe to show to the user.
  final String message;

  /// Original error, if any, kept for debugging.
  final Object? cause;

  /// Optional machine readable code.
  final String? code;

  @override
  String toString() => message;
}

/// Thrown when the user has not configured an API key yet.
class MissingApiKeyException extends AppException {
  const MissingApiKeyException()
    : super('No API key configured. Add your key in Settings first.');
}

/// Thrown when the chosen AI provider is not supported.
class UnsupportedProviderException extends AppException {
  const UnsupportedProviderException(String provider)
    : super('The AI provider "$provider" is not supported.');
}

/// Thrown when the remote AI API rejects the request.
class AiApiException extends AppException {
  const AiApiException(super.message, {super.cause, super.code});
}

/// Thrown when we cannot extract readable text from a photo.
class OcrException extends AppException {
  const OcrException([
    super.message = 'Could not read any text from this photo.',
  ]) : super();
}

/// Thrown when a network call fails (timeout, no connection).
class NetworkException extends AppException {
  const NetworkException({super.cause})
    : super('Network error. Check your connection and try again.');
}

/// Thrown when OCR is used on a platform that has no ML Kit backend.
class UnsupportedPlatformException extends AppException {
  const UnsupportedPlatformException(super.message);
}

/// Thrown when the user has no camera permission.
class PermissionDeniedException extends AppException {
  const PermissionDeniedException()
    : super('Camera permission is required to take a photo.');
}

/// Thrown when stored data cannot be decoded.
class DataDecodeException extends AppException {
  const DataDecodeException(super.message, {super.cause});
}
