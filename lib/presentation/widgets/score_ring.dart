library;

import 'package:flutter/material.dart';

/// Circular 0-100 correctness score gauge used in Control Mode results.

class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.size = 120,
    this.strokeWidth = 10,
  });

  final int score;
  final double size;
  final double strokeWidth;

  Color _color(ColorScheme scheme) {
    if (score >= 85) return const Color(0xFF2E7D32);
    if (score >= 60) return const Color(0xFF84CC16);
    return scheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _color(scheme);
    final clamped = score.clamp(0, 100);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: clamped / 100,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor: scheme.surfaceContainerHighest,
              color: color,
              // TweenAnimationBuilder below drives the visual animation.
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                '${value.round()}%',
                style: TextStyle(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
