library;

import 'package:flutter/material.dart';

/// A large, rounded gradient card used on the Home screen and as a general
/// hero-style call-to-action tile.

class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    this.onTap,
    this.trailing,
    this.badge,
    this.hero = false,
  });

  /// Card title.
  final String title;

  /// One-line subtitle shown under the title.
  final String subtitle;

  /// Leading icon.
  final IconData icon;

  /// Gradient applied to the card background.
  final List<Color> colors;

  /// Tap callback (whole card is tappable).
  final VoidCallback? onTap;

  /// Optional widget pinned to the trailing edge.
  final Widget? trailing;

  /// Small translucent pill shown next to the title.
  final String? badge;

  /// When true the card renders larger (used for the featured mode).
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final iconSize = hero ? 68.0 : 56.0;
    final iconRadius = hero ? 22.0 : 18.0;
    final padding = hero ? const EdgeInsets.all(24) : const EdgeInsets.all(20);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(iconRadius),
                  ),
                  child: Icon(icon, color: Colors.white, size: hero ? 34 : 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: hero ? 21 : 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.24),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                badge!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
