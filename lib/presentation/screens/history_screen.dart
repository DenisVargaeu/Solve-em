library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/solved_problem.dart';
import '../state/history_controller.dart';
import '../widgets/math_text.dart';
import 'check_screen.dart';
import 'solution_screen.dart';
import '../../core/widgets/empty_state.dart';

/// Lists every saved problem, newest first, with per-mode badges.

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HistoryController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (controller.problems.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () => _confirmClear(context, controller),
            ),
        ],
      ),
      body: switch ((controller.loading, controller.problems.isEmpty)) {
        (true, _) => const Center(child: CircularProgressIndicator()),
        (false, true) => const EmptyState(
          icon: Icons.history_rounded,
          title: 'No solved problems yet',
          message:
              'Solve a problem with AI Mode or Control Mode and it will appear here.',
        ),
        _ => ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: controller.problems.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _HistoryTile(
            problem: controller.problems[index],
            onDelete: () => controller.remove(controller.problems[index].id),
          ),
        ),
      },
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    HistoryController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
          'This deletes every saved problem. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.clear();
    }
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.problem, required this.onDelete});

  final SolvedProblem problem;
  final VoidCallback onDelete;

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => switch (problem.mode) {
          SolveMode.control => CheckScreen(problem: problem),
          _ => SolutionScreen(problem: problem),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badge = _modeBadge(problem.mode);

    return Dismissible(
      key: ValueKey(problem.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(Icons.delete_rounded, color: scheme.error),
      ),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: badge.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(badge.icon, color: badge.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badge.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: badge.color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      MathText(
                        problem.problem.isEmpty
                            ? (problem.calculatorExpression.isEmpty
                                  ? 'Problem'
                                  : problem.calculatorExpression)
                            : problem.problem,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _subtitle(context),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (problem.mode == SolveMode.control)
                  Text(
                    '${problem.score}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _scoreColor(scheme),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(BuildContext context) {
    final date = DateFormat('MMM d, HH:mm').format(problem.createdAt.toLocal());
    final extra = switch (problem.mode) {
      SolveMode.control => problem.correct ? ' • Correct' : ' • Needs work',
      SolveMode.noAi when problem.calculatorResult.isNotEmpty =>
        ' • = ${problem.calculatorResult}',
      _ => '',
    };
    return '$date$extra';
  }

  Color _scoreColor(ColorScheme scheme) => problem.score >= 85
      ? const Color(0xFF2E7D32)
      : problem.score >= 60
      ? const Color(0xFFF9A825)
      : scheme.error;

  ({Color color, IconData icon, String label}) _modeBadge(SolveMode mode) {
    return switch (mode) {
      SolveMode.ai => (
        color: const Color(0xFF7C4DFF),
        icon: Icons.auto_awesome_rounded,
        label: 'AI Mode',
      ),
      SolveMode.control => (
        color: const Color(0xFF00897B),
        icon: Icons.fact_check_rounded,
        label: 'Control Mode',
      ),
      SolveMode.noAi => (
        color: const Color(0xFFF9A825),
        icon: Icons.menu_book_rounded,
        label: 'No AI Mode',
      ),
    };
  }
}
