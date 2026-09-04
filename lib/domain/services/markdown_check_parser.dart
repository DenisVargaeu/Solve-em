library;

import 'package:solveem/domain/entities/mistake.dart';
import 'package:solveem/domain/entities/solution_check_result.dart';

/// Parses the **Control Mode** model output when the model answers in Markdown
/// with custom tags instead of strict JSON.
///
/// Expected output shape (every part wrapped in curly-brace tags):
///
/// {score}87{/score}
/// {correct}no{/correct}
///
/// {mistake}You divided both sides by x
/// - **Why it is wrong:** x can be zero, so you lose a solution.
/// - **Do this instead:** Factor instead: $x(x - 2) = 0$
/// {/mistake}
///
/// {hint}A guiding hint without the full answer.{/hint}
/// {feedback}Encouraging, constructive summary.{/feedback}
///
/// The older `[score]` / `[correct]` / `[mistake]` / `[hint]` / `[feedback]`
/// tags are still accepted. The parser is forgiving: the mistake tags may
/// repeat, the bullets may be written in several forms, and when nothing
/// structured is found the whole text is kept as [SolutionCheckResult.rawText].

class MarkdownCheckParser {
  MarkdownCheckParser._();

  /// A single regex matching every tag: `{score}`, `[correct]`, `{mistake}`,
  /// `[hint]`, `{feedback}`. Group 1 is the tag name, group 2 the inline text
  /// on the same line.
  static final RegExp _tag = RegExp(
    r'^\s*[\{\[](score|correct|mistake|hint|feedback)[\}\]]\s*(.*)$',
    caseSensitive: false,
    multiLine: true,
  );

  /// Matches closing tags like `{/mistake}` so they are removed from bodies.
  static final RegExp _closing = RegExp(
    r'\{/\s*(?:score|correct|mistake|hint|feedback)\}\s*',
    caseSensitive: false,
  );

  /// `- **Why it is wrong:** reason`
  static final RegExp _reasonRe = RegExp(
    r'^[-*]?\s*\**\s*Why\s+it\s+is\s+wrong\s*:\s*\**\s*(.*)$',
    caseSensitive: false,
  );

  /// `- **Do this instead:** approach`
  static final RegExp _approachRe = RegExp(
    r'^[-*]?\s*\**\s*(?:Do\s+this\s+instead|What\s+you\s+should\s+do\s+instead|What\s+to\s+do\s+instead|Correct\s+approach)\s*:\s*\**\s*(.*)$',
    caseSensitive: false,
  );

  /// Parses [raw] into a [SolutionCheckResult]. [solutionText] is the
  /// OCR-confirmed student solution, used as a fallback field.
  static SolutionCheckResult parse(String raw, {required String solutionText}) {
    final text = raw.trim();
    final tags = <({int start, int markerEnd, String kind, String inline})>[];

    for (final m in _tag.allMatches(text)) {
      final kind = m.group(1)!.toLowerCase();
      final matched = m.group(0)!;
      // The `^\s*` prefix may consume the newline of the previous line, so
      // locate the real closer from the matched text.
      final closer = matched.indexOf(']');
      final idx = closer == -1 ? matched.indexOf('}') : closer;
      final inline = (m.group(2) ?? '').trim().replaceAll(_closing, '');
      tags.add((
        start: m.start,
        markerEnd: m.start + idx + 1,
        kind: kind,
        inline: inline,
      ));
    }
    tags.sort((a, b) => a.start.compareTo(b.start));

    if (tags.isEmpty) {
      return SolutionCheckResult(solutionText: solutionText, rawText: text);
    }

    var score = 0;
    var correct = false;
    var hasCorrectTag = false;
    final mistakes = <Mistake>[];
    var hint = '';
    var feedback = '';

    for (var i = 0; i < tags.length; i++) {
      final tag = tags[i];
      final body = _body(text, tags, i);
      switch (tag.kind) {
        case 'score':
          final parsed = int.tryParse(tag.inline);
          if (parsed != null) score = parsed.clamp(0, 100).toInt();
        case 'correct':
          correct = _isCorrect(tag.inline);
          hasCorrectTag = true;
        case 'mistake':
          mistakes.add(_toMistake(body));
        case 'hint':
          if (hint.isEmpty) hint = body;
        case 'feedback':
          if (feedback.isEmpty) feedback = body;
      }
    }

    if (correct && score == 0) {
      score = 100;
    }
    if (!hasCorrectTag) correct = score >= 50;

    return SolutionCheckResult(
      solutionText: solutionText,
      correct: correct,
      score: score,
      mistakes: mistakes,
      hint: hint,
      feedback: feedback,
      rawText: text,
    );
  }

  /// Content between this tag and the next one, including any inline text on
  /// the tag's own line.
  static String _body(
    String text,
    List<({int start, int markerEnd, String kind, String inline})> tags,
    int i,
  ) {
    final next = i + 1 < tags.length ? tags[i + 1].start : text.length;
    return text
        .substring(tags[i].markerEnd, next)
        .trim()
        .replaceAll(_closing, '')
        .trim();
  }

  static bool _isCorrect(String value) {
    final v = value.toLowerCase().trim();
    if (v.startsWith('y') || v.startsWith('t') || v.startsWith('c')) {
      return true;
    }
    return false;
  }

  static Mistake _toMistake(String body) {
    final lines = body.split('\n');
    final step = lines.isEmpty ? '' : lines.first.trim();
    var reason = '';
    var approach = '';
    var section = 0; // 0 = step, 1 = reason, 2 = approach
    for (var i = 1; i < lines.length; i++) {
      final content = lines[i].trim();
      if (content.isEmpty) continue;
      final reasonMatch = _reasonRe.firstMatch(lines[i]);
      if (reasonMatch != null) {
        reason = _merge(reason, reasonMatch.group(1)!.trim());
        section = 1;
        continue;
      }
      final approachMatch = _approachRe.firstMatch(lines[i]);
      if (approachMatch != null) {
        approach = _merge(approach, approachMatch.group(1)!.trim());
        section = 2;
        continue;
      }
      if (section == 1) {
        reason = _merge(reason, content);
      } else if (section == 2) {
        approach = _merge(approach, content);
      }
    }
    return Mistake(step: step, reason: reason, correctApproach: approach);
  }

  static String _merge(String existing, String next) =>
      existing.isEmpty ? next : '$existing\n$next';
}
