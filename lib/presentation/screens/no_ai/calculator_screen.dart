library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../domain/entities/solved_problem.dart';
import '../../../domain/services/expression_evaluator.dart';
import '../../state/history_controller.dart';

/// Offline calculator backed by [ExpressionEvaluator].
///
/// Supports `+ - * / ^ % !`, parentheses, constants (`pi`, `e`) and functions
/// (`sqrt`, `sin`, `cos`, …). Successful results are saved to history.

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String? _error;

  void _append(String token) {
    setState(() {
      _error = null;
      _expression += token;
    });
  }

  void _backspace() {
    setState(() {
      _error = null;
      _expression = _expression.isEmpty
          ? ''
          : _expression.substring(0, _expression.length - 1);
    });
  }

  void _clear() {
    setState(() {
      _expression = '';
      _error = null;
    });
  }

  void _evaluate() {
    if (_expression.trim().isEmpty) return;
    try {
      final result = ExpressionEvaluator.evaluateToString(_expression);
      final history = context.read<HistoryController>();
      history.add(
        SolvedProblem.fromCalculator(expression: _expression, result: result),
      );
      if (!mounted) return;
      setState(() {
        _error = null;
        _expression = result;
      });
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  String get _preview {
    if (_expression.trim().isEmpty) return '';
    try {
      return '= ${ExpressionEvaluator.evaluateToString(_expression)}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: SafeArea(
        child: Column(
          children: [
            // ── Display ───────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _preview,
                    style: TextStyle(
                      fontSize: 20,
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _expression.isEmpty ? '0' : _expression,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: scheme.error, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),

            // ── Function row ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _funcButton('√', () => _append('sqrt(')),
                  _funcButton('x²', () => _append('^2')),
                  _funcButton('x³', () => _append('^3')),
                  _funcButton('π', () => _append('pi')),
                  _funcButton('!', () => _append('!')),
                ],
              ),
            ),

            const Spacer(),

            // ── Main pad ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _padButton(
                    'C',
                    scheme.errorContainer,
                    scheme.onErrorContainer,
                    () => _clear(),
                  ),
                  _padButton(
                    '(',
                    scheme.surfaceContainerHighest,
                    scheme.onSurface,
                    () => _append('('),
                  ),
                  _padButton(
                    ')',
                    scheme.surfaceContainerHighest,
                    scheme.onSurface,
                    () => _append(')'),
                  ),
                  _padButton(
                    '÷',
                    scheme.surfaceContainerHighest,
                    scheme.primary,
                    () => _append('/'),
                  ),

                  _padButton(
                    '7',
                    scheme.surfaceContainerHighest,
                    scheme.onSurface,
                    () => _append('7'),
                  ),
                  _padButton(
                    '8',
                    scheme.surfaceContainerHighest,
                    scheme.onSurface,
                    () => _append('8'),
                  ),
                  _padButton(
                    '9',
                    scheme.surfaceContainerHighest,
                    scheme.onSurface,
                    () => _append('9'),
                  ),
                  _padButton(
                    '×',
                    scheme.surfaceContainerHighest,
                    scheme.primary,
                    () => _append('*'),
                  ),

                  _padButton(
                    '4',
                    scheme.surfaceContainerHighest,
                    scheme.onSurface,
                    () => _append('4'),
                  ),
                  _padButton(
                    '5',
                    scheme.surfaceContainerHighest,
                    scheme.onSurface,
                    () => _append('5'),
                  ),
                  _padButton(
                    '6',
                    scheme.surfaceContainerHighest,
                    scheme.onSurface,
                    () => _append('6'),
                  ),
                  _padButton(
                    '−',
                    scheme.surfaceContainerHighest,
                    scheme.primary,
                    () => _append('-'),
                  ),

                  _padButton(
                    '1',
                    scheme.surfaceContainerHighest,
                    scheme.onSurface,
                    () => _append('1'),
                  ),
                  _padButton(
                    '2',
                    scheme.surfaceContainerHighest,
                    scheme.onSurface,
                    () => _append('2'),
                  ),
                  _padButton(
                    '3',
                    scheme.surfaceContainerHighest,
                    scheme.onSurface,
                    () => _append('3'),
                  ),
                  _padButton(
                    '+',
                    scheme.surfaceContainerHighest,
                    scheme.primary,
                    () => _append('+'),
                  ),

                  _padButton(
                    '0',
                    scheme.surfaceContainerHighest,
                    scheme.onSurface,
                    () => _append('0'),
                  ),
                  _padButton(
                    '.',
                    scheme.surfaceContainerHighest,
                    scheme.onSurface,
                    () => _append('.'),
                  ),
                  _padButton(
                    '⌫',
                    scheme.surfaceContainerHighest,
                    scheme.onSurface,
                    () => _backspace(),
                  ),
                  _padButton(
                    '=',
                    scheme.primary,
                    scheme.onPrimary,
                    () => _evaluate(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _funcButton(String label, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilledButton.tonal(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _padButton(
    String label,
    Color background,
    Color foreground,
    VoidCallback onTap,
  ) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Center(
          child: label == '⌫'
              ? Icon(Icons.backspace_outlined, color: foreground, size: 26)
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
        ),
      ),
    );
  }
}
