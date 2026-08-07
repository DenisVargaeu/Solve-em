library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';

import '../../../data/formula_catalog.dart';
import '../../../domain/entities/formula.dart';
import '../../widgets/math_text.dart';

/// Offline reference of common formulas, grouped by topic and rendered as
/// proper math.

class FormulaLibraryScreen extends StatelessWidget {
  const FormulaLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = FormulaCatalog.grouped;

    return Scaffold(
      appBar: AppBar(title: const Text('Formula Library')),
      body: ListView(
        padding: AppSpace.screen,
        children: [
          for (final group in groups) ...[
            _TopicHeader(group.key),
            const SizedBox(height: 10),
            ...group.value.map(
              (formula) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FormulaTile(formula: formula),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _TopicHeader extends StatelessWidget {
  const _TopicHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _FormulaTile extends StatefulWidget {
  const _FormulaTile({required this.formula});

  final Formula formula;

  @override
  State<_FormulaTile> createState() => _FormulaTileState();
}

class _FormulaTileState extends State<_FormulaTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.formula.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                  ),
                  child: MathText(
                    '\$\$ ${widget.formula.latex} \$\$',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.formula.description,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (widget.formula.example != null) ...[
                          const SizedBox(height: 8),
                          MathText(
                            'Example: ${widget.formula.example}',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
