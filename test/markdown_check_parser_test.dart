library;

import 'package:solveem/domain/services/markdown_check_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarkdownCheckParser', () {
    test('parses score, correct, mistakes, hint and feedback', () {
      const raw = r'''
[score] 87

[correct] no

[mistake] You divided both sides by x
- **Why it is wrong:** x can be zero, so you lose a solution.
- **Do this instead:** Factor instead: $x(x - 2) = 0$

[mistake] You forgot to check the answer
- **Why it is wrong:** The result must be verified.
- **Do this instead:** Plug the value back in.

[hint] Try factoring the equation first.

[feedback] You set up the equation correctly, nice work!
''';

      final result = MarkdownCheckParser.parse(raw, solutionText: 'x = 1');

      expect(result.score, 87);
      expect(result.correct, isFalse);
      expect(result.mistakes, hasLength(2));
      expect(result.mistakes[0].step, 'You divided both sides by x');
      expect(result.mistakes[0].reason, contains('x can be zero'));
      expect(result.mistakes[0].correctApproach, contains(r'$x(x - 2) = 0$'));
      expect(result.mistakes[1].reason, 'The result must be verified.');
      expect(result.hint, contains('Try factoring'));
      expect(result.feedback, contains('nice work'));
      expect(result.solutionText, 'x = 1');
    });

    test('derives correct from score when verdict tag is missing', () {
      const raw = r'''
[score] 95

[hint] Nothing to fix.
[feedback] Great job!
''';

      final result = MarkdownCheckParser.parse(raw, solutionText: 'x = 1');

      expect(result.correct, isTrue);
      expect(result.score, 95);
      expect(result.mistakes, isEmpty);
    });

    test('honors an explicit correct=yes with a low score', () {
      const raw = r'''
[score] 40
[correct] yes

[hint] All good.
[feedback] Well done.
''';

      final result = MarkdownCheckParser.parse(raw, solutionText: 'x = 1');

      expect(result.correct, isTrue);
      expect(result.score, 40);
    });

    test('keeps everything as rawText when nothing structured is found', () {
      const raw = 'Just a sentence with no tags.';

      final result = MarkdownCheckParser.parse(raw, solutionText: 'x = 1');

      expect(result.mistakes, isEmpty);
      expect(result.feedback, isEmpty);
      expect(result.hint, isEmpty);
      expect(result.rawText, raw);
      expect(result.solutionText, 'x = 1');
    });

    test('parses the full {}-tag format', () {
      const raw = r'''
{score}65{/score}
{correct}no{/correct}

{mistake}You divided both sides by x
- **Why it is wrong:** x can be zero.
- **Do this instead:** Factor instead: $x(x - 2) = 0$
{/mistake}

{hint}Think about what happens when x is zero.{/hint}
{feedback}Good start, check the division step.{/feedback}
''';

      final result = MarkdownCheckParser.parse(raw, solutionText: 'x = 1');

      expect(result.score, 65);
      expect(result.correct, isFalse);
      expect(result.mistakes, hasLength(1));
      expect(result.mistakes[0].step, 'You divided both sides by x');
      expect(result.mistakes[0].reason, contains('x can be zero'));
      expect(result.mistakes[0].correctApproach, contains(r'$x(x - 2) = 0$'));
      expect(result.hint, contains('when x is zero'));
      expect(result.feedback, contains('Good start'));
      expect(result.rawText, contains('{score}'));
    });

    test('accepts {score} without spaces and a correct verdict', () {
      const raw = r'''
{score}100{/score}
{correct}yes{/correct}
''';

      final result = MarkdownCheckParser.parse(raw, solutionText: 'x = 1');

      expect(result.score, 100);
      expect(result.correct, isTrue);
    });
  });
}
