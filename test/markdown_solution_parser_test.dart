library;

import 'package:solveem/domain/services/markdown_solution_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarkdownSolutionParser', () {
    test('parses steps, answer, explanation and simple explanation', () {
      const raw = r'''
[step1] Factor out the common term
The two terms share a factor of $2x$:

$$2x^2 + 4x = 2x(x + 2)$$

[step2] Solve for x
- Set $2x = 0$
- Set $x + 2 = 0$

**Answer:** $x = 0$ or $x = -2$

**Explanation:** We used the distributive property in reverse.

**Simpler explanation:** Think of factoring as undoing multiplication.
''';

      final result = MarkdownSolutionParser.parse(
        raw,
        fallbackProblem: 'fallback',
      );

      expect(result.problem, 'fallback');
      expect(result.steps, hasLength(2));
      expect(result.steps[0].title, 'Factor out the common term');
      expect(
        result.steps[0].description,
        contains(r'$$2x^2 + 4x = 2x(x + 2)$$'),
      );
      expect(result.steps[1].title, 'Solve for x');
      expect(result.steps[1].description, contains(r'$x + 2 = 0$'));
      expect(result.answer, r'$x = 0$ or $x = -2$');
      expect(result.explanation, contains('distributive property'));
      expect(result.simpleExplanation, contains('undoing multiplication'));
      expect(result.rawText, raw.trim());
    });

    test('handles [Step 2] style tags and bold titles', () {
      const raw = r'''
Some preamble before the steps.

[Step 1] **Find the derivative**
Take the derivative of each term.

[Step 2] Evaluate
Plug in $x = 1$.

**Answer:** 3
''';

      final result = MarkdownSolutionParser.parse(
        raw,
        fallbackProblem: 'fallback',
      );

      expect(result.steps, hasLength(2));
      expect(result.steps[0].title, 'Find the derivative');
      expect(result.steps[1].title, 'Evaluate');
      expect(result.answer, '3');
      expect(result.problem, 'Some preamble before the steps.');
    });

    test('extracts sections without any step tags', () {
      const raw = r'''
**Answer:** 42

**Explanation:** Plain math.
''';

      final result = MarkdownSolutionParser.parse(
        raw,
        fallbackProblem: 'problem',
      );

      expect(result.steps, isEmpty);
      expect(result.answer, '42');
      expect(result.explanation, 'Plain math.');
      expect(result.problem, 'problem');
    });

    test('keeps everything as rawText when nothing structured is found', () {
      const raw = 'Just a sentence with no structure.';

      final result = MarkdownSolutionParser.parse(
        raw,
        fallbackProblem: 'fallback',
      );

      expect(result.steps, isEmpty);
      expect(result.answer, isEmpty);
      expect(result.explanation, isEmpty);
      expect(result.problem, 'fallback');
      expect(result.rawText, raw);
    });

    test('uses a body-only step and numbers it', () {
      const raw = r'''
[step1] The only step
''';

      final result = MarkdownSolutionParser.parse(
        raw,
        fallbackProblem: 'fallback',
      );

      expect(result.steps, hasLength(1));
      expect(result.steps[0].title, 'Step 1');
      expect(result.steps[0].description, 'The only step');
    });

    test('extracts the answer from the {ans} tags', () {
      const raw = r'''
[step1] Divide both sides
Divide by $2$.

[step2] Read the result
The solution follows.

**Answer:** {ans}$x = 4${/ans}

**Explanation:** Isolate $x$.

**Simpler explanation:** Get $x$ alone.
''';

      final result = MarkdownSolutionParser.parse(
        raw,
        fallbackProblem: 'fallback',
      );

      expect(result.steps, hasLength(2));
      expect(result.answer, r'$x = 4$');
      expect(result.answer, isNot(contains('{ans}')));
      expect(result.answer, isNot(contains('{/ans}')));
    });

    test('uses {ans} tags even without an Answer section', () {
      const raw = r'''
[step1] Solve the equation
Work it out.

{ans}50{/ans}
''';

      final result = MarkdownSolutionParser.parse(
        raw,
        fallbackProblem: 'fallback',
      );

      expect(result.answer, '50');
    });

    test('uses {ans} tags without any step tags or Answer section', () {
      const raw = r'''
The product is 6 times 7.

{ans}42{/ans}
''';

      final result = MarkdownSolutionParser.parse(
        raw,
        fallbackProblem: 'fallback',
      );

      expect(result.answer, '42');
      expect(result.steps, isEmpty);
      expect(result.rawText, raw.trim());
    });

    test('falls back to the Answer section when {ans} tags are missing', () {
      const raw = r'''
[step1] Solve the equation
Work it out.

**Answer:** $x = 9$
''';

      final result = MarkdownSolutionParser.parse(
        raw,
        fallbackProblem: 'fallback',
      );

      expect(result.answer, r'$x = 9$');
    });

    test('supports ## heading style and Final Answer header', () {
      const raw = r'''
## Answer
$x = 5$

## Explanation
Substitute back to verify.

## Final Answer
$x = 5$ again

## Simpler explanation
Just guess and check.
''';

      final result = MarkdownSolutionParser.parse(
        raw,
        fallbackProblem: 'fallback',
      );

      expect(result.steps, isEmpty);
      expect(result.answer, contains(r'$x = 5$'));
      expect(result.answer, contains('again'));
      expect(result.explanation, contains('Substitute back'));
      expect(result.simpleExplanation, contains('guess and check'));
    });

    test(
      'falls back to **Step N:** headings when [stepN] tags are missing',
      () {
        const raw = r'''
Let's factor the equation.

**Step 1:** Factor out the common term
Take $2x$ outside the brackets.

**Step 2:** Solve for x
Set each factor to zero.

**Answer:** {ans}x = 0 or x = -2{/ans}
''';

        final result = MarkdownSolutionParser.parse(
          raw,
          fallbackProblem: 'fallback',
        );

        expect(result.steps, hasLength(2));
        expect(result.steps[0].title, 'Factor out the common term');
        expect(result.steps[1].title, 'Solve for x');
        expect(result.answer, 'x = 0 or x = -2');
        expect(result.problem, contains('Let\'s factor the equation.'));
      },
    );

    test('falls back to plain "Step N:" headings', () {
      const raw = r'''
Step 1: Multiply both sides by 2
This cancels the denominator.

Step 2. Subtract 3 from both sides
Leaves $2x = 4$.

Step 3 — Divide by 2
So $x = 2$.
''';

      final result = MarkdownSolutionParser.parse(
        raw,
        fallbackProblem: 'fallback',
      );

      expect(result.steps, hasLength(3));
      expect(result.steps[0].title, 'Multiply both sides by 2');
      expect(result.steps[1].title, 'Subtract 3 from both sides');
      expect(result.steps[2].title, 'Divide by 2');
    });

    test('extracts a prose answer like "The answer is 50."', () {
      const raw = r'''
Multiply 6 by 7 to get the total.

The answer is 42.
''';

      final result = MarkdownSolutionParser.parse(
        raw,
        fallbackProblem: 'fallback',
      );

      expect(result.answer, '42');
      expect(result.steps, isEmpty);
      expect(result.rawText, isNotEmpty);
    });

    test('stripMarkers removes [stepN] and {ans} markers', () {
      expect(
        MarkdownSolutionParser.stripMarkers(
          '[step1] Work it out.\n{ans}42{/ans}',
        ),
        'Work it out.\n42',
      );
      expect(MarkdownSolutionParser.stripMarkers('plain text'), 'plain text');
    });

    test('parses the full {}-tag format', () {
      const raw = r'''
{problem}2x^2 + 4x = 0{/problem}

{step1}Factor out the common term
The two terms share the factor $2x$:

$$2x^2 + 4x = 2x(x + 2)$$
{/step1}

{step2}Solve for x
Use the zero-product property.
{/step2}

{answer}$x = 0$ or $x = -2${/answer}

{explanation}Factor, then solve each factor equal to zero.{/explanation}

{simpler}Unpack the expression, then find when each piece equals zero.{/simpler}
''';

      final result = MarkdownSolutionParser.parse(
        raw,
        fallbackProblem: 'fallback',
      );

      expect(result.problem, '2x^2 + 4x = 0');
      expect(result.steps, hasLength(2));
      expect(result.steps[0].title, 'Factor out the common term');
      expect(result.steps[0].description, contains(r'$2x$'));
      expect(result.steps[1].title, 'Solve for x');
      expect(result.answer, r'$x = 0$ or $x = -2$');
      expect(result.explanation, contains('Factor'));
      expect(result.simpleExplanation, contains('Unpack'));
      expect(result.answer, isNot(contains('{answer}')));
    });

    test('accepts {answer} tags without step tags', () {
      const raw = r'''
{answer}42{/answer}
''';

      final result = MarkdownSolutionParser.parse(
        raw,
        fallbackProblem: 'fallback',
      );

      expect(result.answer, '42');
    });
  });
}
