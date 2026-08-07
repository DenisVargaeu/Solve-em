library;

import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';
import '../../domain/entities/mistake.dart';
import '../../domain/entities/solved_problem.dart';
import '../widgets/math_text.dart';
import '../widgets/score_ring.dart';
import '../widgets/section_card.dart';

/// Shows the result of a **Control Mode** check: score, highlighted mistakes
/// and guiding hints.

class CheckScreen extends StatelessWidget {
  const CheckScreen({super.key, required this.problem});

  final SolvedProblem problem;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final correct = problem.correct;

    return Scaffold(
      appBar: AppBar(title: const Text('Check result')),
      body: ListView(
        padding: AppSpace.screen,
        children: [
          // ── Score headline ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                ScoreRing(score: problem.score),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      correct
                          ? Icons.verified_rounded
                          : Icons.rate_review_rounded,
                      color: correct ? const Color(0xFF2E7D32) : scheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      correct ? 'Looks correct!' : 'Needs some work',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: correct ? const Color(0xFF2E7D32) : scheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (problem.problem.isNotEmpty) ...[
            SectionCard(
              icon: Icons.menu_book_rounded,
              title: 'Problem',
              child: MathText(
                problem.problem,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (problem.solutionText.isNotEmpty) ...[
            SectionCard(
              icon: Icons.edit_note_rounded,
              title: 'Your solution',
              child: MathText(
                problem.solutionText,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Mistakes ───────────────────────────────────────────────────
          if (problem.mistakes.isNotEmpty) ...[
            const _SectionTitle('Mistakes found', Icons.error_outline_rounded),
            const SizedBox(height: 12),
            ...problem.mistakes.indexed.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MistakeCard(index: entry.$1, mistake: entry.$2),
              ),
            ),
            const SizedBox(height: 16),
          ] else if (problem.feedback.isNotEmpty) ...[
            SectionCard(
              icon: Icons.celebration_rounded,
              title: 'Great work',
              titleColor: const Color(0xFF2E7D32),
              child: MathText(
                problem.feedback,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Hint (collapsed to avoid spoiling) ─────────────────────────
          if (problem.hint.isNotEmpty) ...[
            SectionCard(
              icon: Icons.lightbulb_rounded,
              title: 'Hint',
              titleColor: const Color(0xFF84CC16),
              child: _HintReveal(text: problem.hint),
            ),
            const SizedBox(height: 16),
          ],

          if (problem.feedback.isNotEmpty && problem.mistakes.isNotEmpty) ...[
            SectionCard(
              icon: Icons.psychology_rounded,
              title: 'Feedback',
              child: MathText(
                problem.feedback,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (problem.rawText.isNotEmpty &&
              problem.mistakes.isEmpty &&
              problem.feedback.isEmpty) ...[
            SectionCard(
              icon: Icons.notes_rounded,
              title: 'Raw answer',
              child: MathText(
                problem.rawText,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
          ],

          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, this.icon);

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// A highlighted incorrect step with the reason and the fix.
class _MistakeCard extends StatelessWidget {
  const _MistakeCard({required this.index, required this.mistake});

  final int index;
  final Mistake mistake;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: scheme.error.withValues(alpha: 0.4)),
      ),
      padding: AppSpace.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Incorrect step',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.error,
                  ),
                ),
              ),
            ],
          ),
          if (mistake.step.isNotEmpty) ...[
            const SizedBox(height: 12),
            MathText(
              mistake.step,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.lineThrough,
                decorationColor: scheme.error,
                color: scheme.onErrorContainer,
              ),
            ),
          ],
          if (mistake.reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Why it is wrong: ${mistake.reason}',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (mistake.correctApproach.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MathText(
                    'Do this instead: ${mistake.correctApproach}',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Hint text hidden behind a "Reveal" button so students try first.
class _HintReveal extends StatefulWidget {
  const _HintReveal({required this.text});

  final String text;

  @override
  State<_HintReveal> createState() => _HintRevealState();
}

class _HintRevealState extends State<_HintReveal> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    if (!_revealed) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _revealed = true),
          icon: const Icon(Icons.remove_red_eye_rounded),
          label: const Text('Reveal hint'),
        ),
      );
    }
    return MathText(
      widget.text,
      style: const TextStyle(fontSize: 14, height: 1.5),
    );
  }
}
