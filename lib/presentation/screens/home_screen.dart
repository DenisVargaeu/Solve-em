library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/ai_provider.dart';
import '../state/settings_controller.dart';
import 'camera_screen.dart';
import 'chat_screen.dart';
import 'history_screen.dart';
import 'no_ai/no_ai_home_screen.dart';
import 'no_ai/notes_screen.dart';
import 'settings_screen.dart';

/// Home screen: animated hero, mode grid and quick access.
///
/// Sections fade in with a gentle cascade when the screen opens.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Widget _entrance(Interval interval, Widget child) {
    final curved = CurvedAnimation(
      parent: _entranceController,
      curve: interval,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final configured = settings.isConfigured;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BrandBar(
                onHistory: () => _open(context, const HistoryScreen()),
                onSettings: () => _open(context, const SettingsScreen()),
              ),
              const SizedBox(height: 6),
              _entrance(
                const Interval(0.0, 0.45),
                _HeroPanel(
                  onSolve: () =>
                      _open(context, CameraScreen(mode: SolveMode.ai)),
                ),
              ),
              const SizedBox(height: 16),
              _entrance(
                const Interval(0.2, 0.65),
                _AiStatusCard(configured: configured),
              ),
              const SizedBox(height: 30),
              _entrance(
                const Interval(0.35, 0.8),
                const _SectionTitle('Explore tools'),
              ),
              const SizedBox(height: 14),
              _entrance(
                const Interval(0.45, 0.9),
                _buildModeGrid(context),
              ),
              const SizedBox(height: 30),
              _entrance(
                const Interval(0.6, 1.0),
                const _SectionTitle('Your space'),
              ),
              const SizedBox(height: 14),
              _entrance(
                const Interval(0.7, 1.0),
                _QuickRow(
                  onHistory: () => _open(context, const HistoryScreen()),
                  onNotes: () => _open(context, const NotesScreen()),
                  onSettings: () => _open(context, const SettingsScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeGrid(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ModeCard(
                  title: 'AI Mode',
                  tagline: 'Snap & solve',
                  description: 'Full step-by-step solutions from a photo.',
                  icon: Icons.auto_awesome_rounded,
                  colors: const [AppColors.aiViolet, AppColors.aiVioletLight],
                  onTap: () =>
                      _open(context, CameraScreen(mode: SolveMode.ai)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ModeCard(
                  title: 'Control',
                  tagline: 'Check your work',
                  description: 'Score your written solution instantly.',
                  icon: Icons.fact_check_rounded,
                  colors: const [
                    AppColors.controlTeal,
                    AppColors.controlTealLight,
                  ],
                  onTap: () => _open(
                    context,
                    CameraScreen(mode: SolveMode.control),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ModeCard(
                  title: 'Chat',
                  tagline: 'Ask a tutor',
                  description: 'Free-form math help, no photo needed.',
                  icon: Icons.forum_rounded,
                  colors: const [AppColors.chatPink, AppColors.chatPinkLight],
                  onTap: () => _open(context, const ChatScreen()),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ModeCard(
                  title: 'No AI',
                  tagline: 'Offline tools',
                  description: 'Calculator, formulas and notes offline.',
                  icon: Icons.menu_book_rounded,
                  colors: const [
                    AppColors.noAiAmber,
                    AppColors.noAiAmberLight,
                  ],
                  onTap: () => _open(context, const NoAiHomeScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

/// Slim brand row with corner actions.
class _BrandBar extends StatelessWidget {
  const _BrandBar({required this.onHistory, required this.onSettings});

  final VoidCallback onHistory;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.3,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                AppConstants.tagline,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'History',
          onPressed: onHistory,
          icon: const Icon(Icons.history_rounded),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: onSettings,
          icon: const Icon(Icons.settings_rounded),
        ),
      ],
    );
  }
}

/// Animated hero panel with a large camera CTA and a wave-cut bottom.
class _HeroPanel extends StatefulWidget {
  const _HeroPanel({required this.onSolve});

  final VoidCallback onSolve;

  @override
  State<_HeroPanel> createState() => _HeroPanelState();
}

class _HeroPanelState extends State<_HeroPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = scheme.surface;

    return Container(
      height: 360,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(scheme.primary, const Color(0xFF312E81), 0.35)!,
            Color.lerp(scheme.primary, scheme.tertiary, 0.55)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.35),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          _AmbientBlobs(controller: _float),
          _FloatingSymbols(controller: _float),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'AI-powered math sidekick',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Snap it.\nSolved it.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Point your camera at any math problem and get a clear step-by-step solution.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _CameraCta(onTap: widget.onSolve),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Start solving',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Tap the camera and snap a problem',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 26),
              painter: _WavePainter(color: surface),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slowly drifting glow blobs behind the hero content.
class _AmbientBlobs extends StatelessWidget {
  const _AmbientBlobs({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value * 2 * math.pi;
        return Stack(
          children: [
            Positioned(
              left: -60 + math.sin(t) * 14,
              top: -40 + math.cos(t) * 10,
              child: _Blob(
                size: 190,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              right: -70 + math.cos(t) * 12,
              bottom: -30 + math.sin(t) * 12,
              child: _Blob(
                size: 210,
                color: Colors.deepPurple.withValues(alpha: 0.22),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// Decorative math symbols that gently float around the hero.
class _FloatingSymbols extends StatelessWidget {
  const _FloatingSymbols({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value * 2 * math.pi;
        return Stack(
          children: [
            Positioned(
              right: 18,
              top: 30 + math.sin(t) * 6,
              child: _Symbol('∑', size: 52),
            ),
            Positioned(
              right: 92,
              top: 150 + math.cos(t) * 8,
              child: _Symbol('√', size: 40),
            ),
            Positioned(
              right: 30,
              top: 96 + math.sin(t + 1.4) * 7,
              child: _Symbol('π', size: 30),
            ),
            Positioned(
              right: 150,
              top: 26 + math.cos(t + 0.7) * 6,
              child: _Symbol('x²', size: 26),
            ),
          ],
        );
      },
    );
  }
}

class _Symbol extends StatelessWidget {
  const _Symbol(this.glyph, {required this.size});

  final String glyph;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      glyph,
      style: TextStyle(
        fontSize: size,
        color: Colors.white.withValues(alpha: 0.16),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

/// Large circular camera shutter button that anchors the primary action.
class _CameraCta extends StatelessWidget {
  const _CameraCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.15),
              width: 3,
            ),
          ),
          child: Icon(
            Icons.camera_alt_rounded,
            size: 34,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Sine-wave cutout that transitions the hero into the page background.
class _WavePainter extends CustomPainter {
  const _WavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0, h);
    path.lineTo(0, h * 0.45);
    for (double x = 0; x <= w; x += 1) {
      final y = h * 0.45 +
          math.sin(x / w * math.pi * 2) * (h * 0.22);
      path.lineTo(x, y);
    }
    path.lineTo(w, h);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => oldDelegate.color != color;
}

/// Compact card showing the AI provider readiness.
class _AiStatusCard extends StatelessWidget {
  const _AiStatusCard({required this.configured});

  final bool configured;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsController>();

    return Material(
      color: configured
          ? scheme.primaryContainer.withValues(alpha: 0.5)
          : scheme.errorContainer.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: configured
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: configured ? AppColors.success : scheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  configured
                      ? '${settings.providerLabel} • ${_model(settings)}'
                      : 'Add an API key to unlock AI modes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: configured
                        ? scheme.onPrimaryContainer
                        : scheme.onErrorContainer,
                  ),
                ),
              ),
              if (!configured)
                const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _model(SettingsController settings) =>
      settings.settings.model.isEmpty ? 'default model' : settings.settings.model;
}

/// Section heading with a short accent bar.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

/// Full-gradient mode card for the 2-column grid.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.tagline,
    required this.description,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String tagline;
  final String description;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_outward_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 20,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tagline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Row of quick-access tiles.
class _QuickRow extends StatelessWidget {
  const _QuickRow({
    required this.onHistory,
    required this.onNotes,
    required this.onSettings,
  });

  final VoidCallback onHistory;
  final VoidCallback onNotes;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickTile(
            icon: Icons.history_rounded,
            label: 'History',
            onTap: onHistory,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickTile(
            icon: Icons.sticky_note_2_rounded,
            label: 'Notes',
            onTap: onNotes,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickTile(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: onSettings,
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      shadowColor: scheme.shadow.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: scheme.primary, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
