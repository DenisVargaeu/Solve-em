library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/solved_problem.dart';

/// Builds shareable output (plain text and a PNG image) from a [SolvedProblem].
///
/// The image is rendered with [TextPainter] onto a branded card so the user can
/// share a solution without needing the app open on the other side.

abstract final class SolutionShare {
  SolutionShare._();

  static const double _padding = 48;
  static const double _lineGap = 18;

  static const Color _green = Color(0xFF15803D);
  static const Color _ink = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF64748B);
  static const Color _bg = Color(0xFFF0FDF4);

  /// Plain-text representation of the problem and its solution.
  static String buildText(SolvedProblem problem) {
    final lines = <String>[
      "Solve 'em — Solution",
      'Solved on ${_formatDate(problem.createdAt)}',
      '',
    ];

    void heading(String text) => lines
      ..add(text)
      ..add('');

    if (problem.problem.trim().isNotEmpty) {
      heading('Problem');
      lines.add(problem.problem.trim());
      lines.add('');
    }

    if (problem.answer.trim().isNotEmpty) {
      heading('Final answer');
      lines.add(problem.answer.trim());
      lines.add('');
    }

    if (problem.steps.isNotEmpty) {
      heading('Step-by-step solution');
      for (var i = 0; i < problem.steps.length; i++) {
        final step = problem.steps[i];
        lines.add('${i + 1}. ${step.title.trim()}');
        if (step.description.trim().isNotEmpty) {
          lines.add(step.description.trim());
        }
        lines.add('');
      }
    }

    if (problem.explanation.trim().isNotEmpty) {
      heading('Detailed explanation');
      lines.add(problem.explanation.trim());
      lines.add('');
    }

    if (problem.simpleExplanation.trim().isNotEmpty) {
      heading('Simpler explanation');
      lines.add(problem.simpleExplanation.trim());
      lines.add('');
    }

    if (problem.mode == SolveMode.control && problem.feedback.isNotEmpty) {
      heading('Check result');
      lines.add('Score: ${problem.score}/100'
          '${problem.correct ? ' — fully correct' : ''}');
      lines.add('');
      for (final mistake in problem.mistakes) {
        lines.add('Mistake: ${mistake.step.trim()}');
        lines.add('• Why: ${mistake.reason.trim()}');
        lines.add('• Instead: ${mistake.correctApproach.trim()}');
        lines.add('');
      }
      if (problem.hint.trim().isNotEmpty) {
        heading('Hint');
        lines.add(problem.hint.trim());
        lines.add('');
      }
      lines.add('Feedback: ${problem.feedback.trim()}');
      lines.add('');
    }

    if (problem.mode == SolveMode.noAi &&
        problem.calculatorExpression.isNotEmpty) {
      heading('Calculation');
      lines.add('${problem.calculatorExpression.trim()} = '
          '${problem.calculatorResult.trim()}');
      lines.add('');
    }

    if (problem.rawText.trim().isNotEmpty &&
        problem.answer.isEmpty &&
        problem.steps.isEmpty &&
        problem.explanation.isEmpty &&
        problem.feedback.isEmpty) {
      heading('Solution');
      lines.add(problem.rawText.trim());
      lines.add('');
    }

    return lines.join('\n').trimRight();
  }

  /// Renders the solution as a PNG [Uint8List] on a branded card.
  static Future<Uint8List> renderImage(
    SolvedProblem problem, {
    double pixelWidth = 1080,
  }) async {
    final maxWidth = pixelWidth - _padding * 2;

    final headerPainter = TextPainter(
      text: TextSpan(
        text: "Solve 'em — Solution",
        style: const TextStyle(
          color: _green,
          fontSize: 44,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final subtitlePainter = TextPainter(
      text: TextSpan(
        text: 'Solved on ${_formatDate(problem.createdAt)}',
        style: const TextStyle(color: _muted, fontSize: 26),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    final blocks = _imageBlocks(problem);
    final painters = <TextPainter>[];
    var totalHeight =
        _padding * 2 + headerPainter.height + 8 + subtitlePainter.height + 32;
    for (final block in blocks) {
      final painter = TextPainter(
        text: block,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);
      painters.add(painter);
      totalHeight += painter.height + (block == blocks.last ? 0 : _lineGap);
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, pixelWidth, totalHeight),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, pixelWidth, totalHeight),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(24, 24, pixelWidth - 48, totalHeight - 48),
        const Radius.circular(24),
      ),
      Paint()
        ..color = _bg
        ..style = PaintingStyle.fill,
    );

    var y = _padding;
    headerPainter.paint(canvas, Offset(_padding, y));
    y += headerPainter.height + 8;
    subtitlePainter.paint(canvas, Offset(_padding, y));
    y += subtitlePainter.height + 32;

    for (var i = 0; i < painters.length; i++) {
      painters[i].paint(canvas, Offset(_padding, y));
      y += painters[i].height + (i == painters.length - 1 ? 0 : _lineGap);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(pixelWidth.toInt(), totalHeight.ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return bytes!.buffer.asUint8List();
  }

  static List<TextSpan> _imageBlocks(SolvedProblem problem) {
    final heading = TextStyle(color: _green, fontSize: 27, fontWeight: FontWeight.w700);
    final body = TextStyle(color: _ink, fontSize: 27);
    final blocks = <TextSpan>[];

    void section(String label) =>
        blocks.add(TextSpan(text: '\n$label\n\n', style: heading));

    void textBlock(String value) {
      if (value.trim().isEmpty) return;
      blocks.add(TextSpan(text: value.trim(), style: body));
    }

    if (problem.problem.trim().isNotEmpty) {
      section('PROBLEM');
      textBlock(problem.problem);
    }

    if (problem.answer.trim().isNotEmpty) {
      section('FINAL ANSWER');
      textBlock(problem.answer);
    }

    if (problem.steps.isNotEmpty) {
      section('STEP-BY-STEP SOLUTION');
      for (var i = 0; i < problem.steps.length; i++) {
        final step = problem.steps[i];
        blocks.add(
          TextSpan(
            text: '${i + 1}. ${step.title.trim()}\n',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 27,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        textBlock(step.description);
        blocks.add(const TextSpan(text: '\n'));
      }
    }

    if (problem.explanation.trim().isNotEmpty) {
      section('DETAILED EXPLANATION');
      textBlock(problem.explanation);
    }

    if (problem.simpleExplanation.trim().isNotEmpty) {
      section('SIMPLER EXPLANATION');
      textBlock(problem.simpleExplanation);
    }

    if (problem.mode == SolveMode.control && problem.feedback.isNotEmpty) {
      section('CHECK RESULT');
      textBlock('Score: ${problem.score}/100'
          '${problem.correct ? ' — fully correct' : ''}');
      for (final mistake in problem.mistakes) {
        textBlock('Mistake: ${mistake.step.trim()}');
        textBlock('Why: ${mistake.reason.trim()}');
        textBlock('Instead: ${mistake.correctApproach.trim()}');
      }
      if (problem.hint.trim().isNotEmpty) {
        textBlock('Hint: ${problem.hint.trim()}');
      }
      textBlock('Feedback: ${problem.feedback.trim()}');
    }

    if (problem.mode == SolveMode.noAi &&
        problem.calculatorExpression.isNotEmpty) {
      section('CALCULATION');
      textBlock('${problem.calculatorExpression.trim()} = '
          '${problem.calculatorResult.trim()}');
    }

    if (problem.rawText.trim().isNotEmpty &&
        problem.answer.isEmpty &&
        problem.steps.isEmpty &&
        problem.explanation.isEmpty &&
        problem.feedback.isEmpty) {
      section('SOLUTION');
      textBlock(problem.rawText);
    }

    return blocks;
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}