library;

import 'package:ai_photomat/domain/entities/ai_analysis_result.dart';
import 'package:ai_photomat/domain/entities/solution_step.dart';

/// Parses the **AI Mode** model output when the model answers in Markdown with
/// custom tags instead of strict JSON.
///
/// Expected output shape (every part wrapped in curly-brace tags):
///
/// {problem}2x^2 + 4x = 0{/problem}
///
/// {step1}Factor out the common term
/// Take the largest common factor outside the brackets...
/// {/step1}
///
/// {step2}Solve for x
/// ...
/// {/step2}
///
/// {answer}$x = 0$ or $x = -2${/answer}
///
/// {explanation}Short method summary{/explanation}
///
/// {simpler}Everyday-language version{/simpler}
///
/// Older shapes are still accepted as fallbacks: `[stepN]` tags, `**Answer:**`
/// / `**Explanation:**` / `**Simpler explanation:**` sections, `{ans}` answer
/// tags and "The answer is ..." prose. When nothing structured is found the
/// whole text is kept as [AiAnalysisResult.rawText] so the answer screen can
/// still render it.

class MarkdownSolutionParser {
  MarkdownSolutionParser._();

  /// Matches `{step1}`, `[step1]`, `[Step 2]`, `{step 03}`, ...
  static final RegExp _stepTag = RegExp(
    r'[\{\[]step\s*\d+[\}\]]',
    caseSensitive: false,
  );

  /// Matches `{/step1}` closing tags so they are removed from step bodies.
  static final RegExp _stepClosing = RegExp(
    r'\{/\s*step\s*\d+\}\s*',
    caseSensitive: false,
  );

  /// Matches `{answer}...{/answer}` (or the older `{ans}...{/ans}`) so the
  /// final answer can be extracted exactly. Group 1 is `{ans}`, group 2
  /// `{answer}`.
  static final RegExp _ansTag = RegExp(
    r'\{ans\}(.*?)\{/ans\}|\{answer\}(.*?)\{/answer\}',
    caseSensitive: false,
    dotAll: true,
  );

  /// Removes stray `{ans}` / `{/ans}` / `{answer}` / `{/answer}` markers.
  static final RegExp _ansMarker = RegExp(
    r'\{/(?:ans|answer)\}|\{(?:ans|answer)\}',
    caseSensitive: false,
  );

  /// Matches `{explanation}...{/explanation}`.
  static final RegExp _explanationTag = RegExp(
    r'\{explanation\}([\s\S]*?)\{/explanation\}',
    caseSensitive: false,
  );

  /// Matches `{simpler}...{/simpler}` (also accepts `{simple explanation}`).
  static final RegExp _simplerTag = RegExp(
    r'\{(?:simpler|simple explanation|simple_explanation)\}([\s\S]*?)\{/(?:simpler|simple explanation|simple_explanation)\}',
    caseSensitive: false,
  );

  /// Matches `{problem}...{/problem}`.
  static final RegExp _problemTag = RegExp(
    r'\{problem\}([\s\S]*?)\{/problem\}',
    caseSensitive: false,
  );

  /// Matches `**Answer:**`, `## Answer`, `Explanation:`, `Simpler
  /// explanation:` and similar section headers. A plain sentence starting with
  /// "Answer ..." is NOT matched (either a `#` heading prefix or a trailing
  /// colon is required). Inline text on the header line is captured in group 2.
  static final RegExp _sectionHeader = RegExp(
    r'^(?:#{1,6}\s+)?(?:\*\*)?((?:(?:final\s+)?answer)|explanation|(?:simpler?|simple)\s+explanation)(?:\*\*)?(?:\s*[:：]\s*\**\s*(.*)$|$)',
    caseSensitive: false,
    multiLine: true,
  );

  /// Matches step headings like `Step 1:`, `**Step 1:**` or `### Step 1` used
  /// when the model ignores the tags.
  static final RegExp _stepHeading = RegExp(
    r'^[ \t]*(?:\*\*|#{1,6}[ \t]*)?step[ \t]*\d+[ \t]*(?:[:：.．\-—–)）][ \t]*)*(?:\*\*)?[ \t]*',
    caseSensitive: false,
    multiLine: true,
  );

  /// Last-resort final answer written in plain prose, e.g. "The answer is 50."
  /// or "the final answer is x = 2". Only used when nothing more structured is
  /// found.
  static final RegExp _proseAnswer = RegExp(
    r'(?:the\s+)?(?:final\s+)?answer\s+is\s*[:：]?\s*(.+)',
    caseSensitive: false,
  );

  /// Removes stray `{stepN}` / `{/stepN}` / `{ans}` / `{answer}` / section
  /// markers from model output.
  static final RegExp _modelMarker = RegExp(
    r'[\{\[]step\s*\d+[\}\]]\s*|\{/(?:ans|answer|explanation|simpler|simple explanation|simple_explanation|problem)\}\s*|\{(?:ans|answer|explanation|simpler|simple explanation|simple_explanation|problem)\}\s*',
    caseSensitive: false,
  );

  /// Parses [raw] into an [AiAnalysisResult].
  ///
  /// [fallbackProblem] is the OCR-confirmed problem text; it is used whenever
  /// the model does not restate the problem itself.
  static AiAnalysisResult parse(String raw, {required String fallbackProblem}) {
    final text = raw.trim();
    final tags = _stepTag.allMatches(text).toList();

    // The trailing {answer} / {explanation} / {simpler} tags (or the legacy
    // **Answer:** / **Explanation:** / **Simpler explanation:** sections)
    // must not be treated as part of the last step, so everything from the
    // first meta marker onward is handled separately.
    var metaStart = _firstSectionHeader(text);
    for (final m in [_ansTag, _explanationTag, _simplerTag]) {
      final first = m.firstMatch(text);
      if (first != null && (metaStart == -1 || first.start < metaStart)) {
        metaStart = first.start;
      }
    }
    if (tags.isNotEmpty && metaStart != -1 && metaStart < tags.last.end) {
      metaStart = -1;
    }

    final stepsRegion = metaStart == -1 ? text : text.substring(0, metaStart);

    // When the model skips the [stepN] tags, fall back to "Step N:" headings.
    final markers = tags.isNotEmpty
        ? tags.map((m) => (start: m.start, end: m.end)).toList()
        : _headingSteps(stepsRegion);

    if (markers.isEmpty) {
      final sections = _extract(text);
      final sectionAnswer = _preferAnsTag(sections.answer, text);
      final proseAnswer = _lastResortAnswer(text);
      final hasSections =
          sectionAnswer.isNotEmpty ||
          sections.explanation.isNotEmpty ||
          sections.simple.isNotEmpty ||
          proseAnswer.isNotEmpty;
      if (hasSections) {
        return AiAnalysisResult(
          problem: sections.problem.isNotEmpty
              ? sections.problem
              : fallbackProblem,
          answer: sectionAnswer.isNotEmpty ? sectionAnswer : proseAnswer,
          explanation: sections.explanation,
          simpleExplanation: sections.simple,
          rawText: text,
        );
      }
      // Nothing structured — keep the whole document as the raw answer.
      return AiAnalysisResult(problem: fallbackProblem, rawText: text);
    }

    final preamble = stepsRegion.substring(0, markers.first.start).trim();
    final steps = <SolutionStep>[];
    for (var i = 0; i < markers.length; i++) {
      final end = i + 1 < markers.length
          ? markers[i + 1].start
          : stepsRegion.length;
      steps.add(_toStep(stepsRegion.substring(markers[i].end, end), index: i));
    }

    final sections = metaStart == -1
        ? _extract('')
        : _extract(text.substring(metaStart));
    final answer = _preferAnsTag(sections.answer, text);
    final problemTag = _problemTag.firstMatch(text)?.group(1)?.trim() ?? '';
    return AiAnalysisResult(
      problem: problemTag.isNotEmpty
          ? problemTag
          : preamble.isNotEmpty
          ? preamble
          : fallbackProblem,
      answer: answer.isNotEmpty ? answer : _lastResortAnswer(text),
      steps: steps,
      explanation: sections.explanation,
      simpleExplanation: sections.simple,
      rawText: text,
    );
  }

  /// Returns the start/end offsets of every "Step N:" heading in [text].
  static List<({int start, int end})> _headingSteps(String text) => _stepHeading
      .allMatches(text)
      .map((m) => (start: m.start, end: m.end))
      .toList();

  /// Finds the final answer written in plain prose, e.g. "The answer is 50."
  /// Returns an empty string when none is found.
  static String _lastResortAnswer(String text) {
    final m = _proseAnswer.firstMatch(text);
    if (m == null) return '';
    return m.group(1)!.trim().replaceFirst(RegExp(r'[.!。*]+\s*$'), '').trim();
  }

  /// Removes stray `[stepN]` / `{ans}` / `{/ans}` markers from model output,
  /// e.g. before showing the raw fallback card.
  static String stripMarkers(String text) =>
      text.replaceAll(_modelMarker, '').trim();

  /// The content of the `{answer}` / `{ans}` tags is the authoritative final
  /// answer; the `**Answer:**` section is used only when the tags are missing.
  static String _preferAnsTag(String sectionAnswer, String text) {
    final m = _ansTag.firstMatch(text);
    final tagged = m == null ? '' : (m.group(1) ?? m.group(2) ?? '').trim();
    return tagged.isNotEmpty ? tagged : sectionAnswer;
  }

  /// Index of the first section header in [text], or -1 when there is none.
  static int _firstSectionHeader(String text) =>
      _sectionHeader.firstMatch(text)?.start ?? -1;

  /// Converts the raw text after a `[stepN]` tag into a [SolutionStep]. The
  /// first line becomes the title, the rest the description. A step with only
  /// a body is still kept, using "Step N" as its title.
  static SolutionStep _toStep(String body, {required int index}) {
    final text = body.trim().replaceAll(_stepClosing, '');
    final newline = text.indexOf('\n');
    final String title;
    final String description;
    if (newline == -1) {
      title = text;
      description = '';
    } else {
      title = text.substring(0, newline).trim();
      description = text.substring(newline + 1).trim();
    }
    final cleanTitle = title
        .replaceFirst(RegExp(r'^\**\s*'), '')
        .replaceFirst(
          RegExp(r'^\s*step\s*\d+\s*[:：.\-—–)]*\s*', caseSensitive: false),
          '',
        )
        .replaceFirst(RegExp(r'\**\s*$'), '');
    if (description.isEmpty) {
      return SolutionStep(title: 'Step ${index + 1}', description: cleanTitle);
    }
    return SolutionStep(
      title: cleanTitle.isEmpty ? 'Step ${index + 1}' : cleanTitle,
      description: description,
    );
  }

  /// Extracts the `{answer}` / `{explanation}` / `{simpler}` / `{problem}`
  /// tag contents from [text], falling back to the legacy `**Answer:**`,
  /// `**Explanation:**` and `**Simpler explanation:**` section headers when a
  /// given field has no tag.
  static ({String problem, String answer, String explanation, String simple})
  _extract(String text) {
    var problem = _problemTag.firstMatch(text)?.group(1)?.trim() ?? '';
    final taggedAnswer = _preferAnsTag('', text);
    var answer = taggedAnswer;
    var explanation = _explanationTag.firstMatch(text)?.group(1)?.trim() ?? '';
    var simple = _simplerTag.firstMatch(text)?.group(1)?.trim() ?? '';

    final headers = _sectionHeader.allMatches(text).toList();
    if (problem.isEmpty) {
      problem = text
          .substring(0, headers.isEmpty ? text.length : headers.first.start)
          .trim();
    }

    for (var i = 0; i < headers.length; i++) {
      final match = headers[i];
      final kind = match.group(1)!.trim().toLowerCase();
      final inline = (match.group(2) ?? '').trim();
      final body = inline.isNotEmpty
          ? inline
          : text
                .substring(
                  match.end,
                  i + 1 < headers.length ? headers[i + 1].start : text.length,
                )
                .trim();

      if (kind == 'answer' || kind == 'final answer') {
        if (taggedAnswer.isEmpty) {
          answer = _merge(answer, body.replaceAll(_ansMarker, '').trim());
        }
      } else if (kind == 'explanation') {
        explanation = _merge(explanation, body);
      } else if (kind == 'simple explanation' ||
          kind == 'simpler explanation') {
        simple = _merge(simple, body);
      }
    }

    return (
      problem: problem,
      answer: answer,
      explanation: explanation,
      simple: simple,
    );
  }

  static String _merge(String existing, String next) =>
      existing.isEmpty ? next : '$existing\n\n$next';
}
