library;

/// Parses text returned by LLMs into JSON.
///
/// LLMs frequently wrap JSON in ```json fences, add prose around it or leave
/// trailing commas. This parser normalizes all of that before handing the
/// result to `jsonDecode`.

import 'dart:convert';

abstract final class JsonParser {
  JsonParser._();

  /// Extracts the first JSON object `{ ... }` from [raw] and decodes it.
  ///
  /// Throws a [FormatException] when nothing parseable is found.
  static Map<String, dynamic> decodeObject(String raw) {
    final start = _firstBrace(raw);
    if (start == -1) {
      throw const FormatException('No JSON object found in model output.');
    }

    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < raw.length; i++) {
      final ch = raw[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == r'\') {
          escaped = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
      } else if (ch == '{') {
        depth++;
      } else if (ch == '}') {
        depth--;
        if (depth == 0) {
          return _decode(raw.substring(start, i + 1));
        }
      }
    }
    throw const FormatException('Unbalanced JSON object in model output.');
  }

  /// Removes Markdown fences and trailing commas, then decodes.
  static Map<String, dynamic> _decode(String candidate) {
    var text = candidate.trim();
    if (text.startsWith('```')) {
      final firstNewline = text.indexOf('\n');
      text = text.substring(firstNewline + 1);
      text = text.endsWith('```') ? text.substring(0, text.length - 3) : text;
    }
    text = text
        .replaceAll(RegExp(r',\s*}'), '}')
        .replaceAll(RegExp(r',\s*\]'), ']');
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Decoded JSON is not an object.');
    }
    return decoded;
  }

  /// First index of `{` outside of any markdown fence/backticks.
  static int _firstBrace(String raw) {
    var inFence = false;
    for (var i = 0; i < raw.length; i++) {
      if (raw.startsWith('```', i)) {
        inFence = !inFence;
        i += 2;
        continue;
      }
      if (!inFence && raw[i] == '{') return i;
    }
    return -1;
  }
}
