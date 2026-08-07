library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/theme/app_dimensions.dart';
import '../../domain/entities/solved_problem.dart';
import '../../domain/services/markdown_solution_parser.dart';
import '../../domain/usecases/ask_follow_up_usecase.dart';
import '../di/app_dependencies.dart';
import '../state/settings_controller.dart';
import '../widgets/math_text.dart';
import '../widgets/section_card.dart';
import '../widgets/step_card.dart';

/// Shows the AI-generated step-by-step solution for a problem.
///
/// Also supports asking follow-up questions about the solution.

class SolutionScreen extends StatefulWidget {
  const SolutionScreen({super.key, required this.problem});

  final SolvedProblem problem;

  @override
  State<SolutionScreen> createState() => _SolutionScreenState();
}

class _SolutionScreenState extends State<SolutionScreen> {
  bool _showFullExplanation = false;
  bool _showSimpleExplanation = false;
  bool _followUpBusy = false;

  @override
  Widget build(BuildContext context) {
    final problem = widget.problem;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solution'),
        actions: [
          IconButton(
            tooltip: 'Ask a follow-up question',
            icon: const Icon(Icons.question_answer_rounded),
            onPressed: _followUpBusy ? null : _askFollowUp,
          ),
        ],
      ),
      body: ListView(
        padding: AppSpace.screen,
        children: [
          _ProblemHeader(problem: problem),
          const SizedBox(height: 16),

          if (problem.answer.isNotEmpty) ...[
            SectionCard(
              icon: Icons.check_circle_rounded,
              title: 'Final answer',
              titleColor: scheme.primary,
              child: MathText(
                problem.answer,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (problem.steps.isNotEmpty) ...[
            const _SectionTitle(
              'Step-by-step solution',
              Icons.format_list_numbered_rounded,
            ),
            const SizedBox(height: 12),
            ...List.generate(problem.steps.length, (i) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == problem.steps.length - 1 ? 0 : 10,
                ),
                child: StepCard(
                  index: i,
                  step: problem.steps[i],
                  initiallyExpanded: i == 0,
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          if (problem.explanation.isNotEmpty) ...[
            SectionCard(
              icon: Icons.menu_book_rounded,
              title: 'Detailed explanation',
              child: _ExpandableText(
                expanded: _showFullExplanation,
                text: problem.explanation,
                onToggle: () => setState(
                  () => _showFullExplanation = !_showFullExplanation,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (problem.simpleExplanation.isNotEmpty) ...[
            SectionCard(
              icon: Icons.emoji_objects_rounded,
              title: 'Simpler explanation',
              child: _ExpandableText(
                expanded: _showSimpleExplanation,
                text: problem.simpleExplanation,
                onToggle: () => setState(
                  () => _showSimpleExplanation = !_showSimpleExplanation,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (problem.rawText.isNotEmpty &&
              problem.answer.isEmpty &&
              problem.steps.isEmpty &&
              problem.explanation.isEmpty &&
              problem.simpleExplanation.isEmpty) ...[
            SectionCard(
              icon: Icons.notes_rounded,
              title: 'Solution',
              child: MathText(
                MarkdownSolutionParser.stripMarkers(problem.rawText),
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _askFollowUp() async {
    final deps = context.read<AppDependencies>();
    final settings = context.read<SettingsController>().settings;
    final question = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _FollowUpSheet(),
    );
    if (question == null || question.trim().isEmpty) return;
    if (!mounted) return;

    setState(() => _followUpBusy = true);
    try {
      final answer = await deps.askFollowUp(
        AskFollowUpParams(
          settings: settings,
          problem: widget.problem.problem,
          solutionContext: [
            if (widget.problem.answer.isNotEmpty)
              'Answer: ${widget.problem.answer}',
            ...widget.problem.steps.map(
              (s) => '• ${s.title}: ${s.description}',
            ),
            if (widget.problem.explanation.isNotEmpty)
              'Explanation: ${widget.problem.explanation}',
          ].join('\n'),
          question: question,
        ),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) =>
            _FollowUpAnswerDialog(question: question, answer: answer),
      );
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _followUpBusy = false);
    }
  }
}

class _ProblemHeader extends StatelessWidget {
  const _ProblemHeader({required this.problem});

  final SolvedProblem problem;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Problem',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MathText(
            problem.problem.isEmpty
                ? 'No problem text extracted.'
                : problem.problem,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          if (problem.imagePath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _ImageViewer(imagePath: problem.imagePath!),
                  ),
                ),
                child: Image.file(
                  // ignore: avoid_dynamic_calls
                  File(problem.imagePath!),
                  height: 140,
                  width: 140,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
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

class _ExpandableText extends StatelessWidget {
  const _ExpandableText({
    required this.expanded,
    required this.text,
    required this.onToggle,
  });

  final bool expanded;
  final String text;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          firstChild: MathText(
            text,
            maxLines: 3,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          secondChild: MathText(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onToggle,
            child: Text(expanded ? 'Show less' : 'Show more'),
          ),
        ),
      ],
    );
  }
}

class _FollowUpSheet extends StatefulWidget {
  const _FollowUpSheet();

  @override
  State<_FollowUpSheet> createState() => _FollowUpSheetState();
}

class _FollowUpSheetState extends State<_FollowUpSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ask a follow-up question',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'For example: "Why did you factor out the 2?"',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => Navigator.of(context).pop(_controller.text),
            decoration: const InputDecoration(hintText: 'Your question…'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_controller.text),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Ask'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUpAnswerDialog extends StatelessWidget {
  const _FollowUpAnswerDialog({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.smart_toy_rounded),
          SizedBox(width: 8),
          Text("Solve 'em says"),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              question,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),
            MathText(answer, style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            // ignore: avoid_dynamic_calls
            File(imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
