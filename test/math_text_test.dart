import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_photomat/presentation/widgets/math_text.dart';

Finder _mathWidgets() =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == 'Math');

void main() {
  testWidgets('renders markdown and inline math', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathText(
              r'**Factor** the quadratic $x^2 + 2x + 1$.'
              '\n\n'
              r'- First step'
              '\n'
              r'- Second step'
              '\n\n'
              r'Display: $$\frac{a}{b}$$',
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(_mathWidgets(), findsNWidgets(2));
    expect(find.byType(RichText), findsWidgets);
  });

  testWidgets('renders plain text with ellipsis for maxLines', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 80,
            child: MathText('A short title', maxLines: 1),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(MarkdownBody), findsNothing);
    expect(find.text('A short title'), findsOneWidget);
  });

  testWidgets('keeps standalone dollar amount plain', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathText(r'The price is $5. Pay in cash.'),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(_mathWidgets(), findsNothing);
    expect(find.byType(RichText), findsWidgets);
  });
}
