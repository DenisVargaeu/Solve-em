library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../domain/entities/ai_provider.dart';
import '../state/app_controller.dart';
import '../state/settings_controller.dart';
import 'camera_screen.dart';
import 'chat_screen.dart';
import 'history_screen.dart';
import 'no_ai/no_ai_home_screen.dart';
import 'no_ai/notes_screen.dart';
import 'settings_screen.dart';

/// Home screen: a bold hero, meaningful quick actions and a mode hub.
///
/// The layout is built around a large "start" hero with two clear paths
/// (solve with the camera / ask the tutor), a compact capability strip, and a
/// reshaped tool grid. Elements cascade in with a gentle entrance animation.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..forward();

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Widget _entrance(Interval interval, Widget child) {
    if (context.watch<AppController>().reduceMotion) return child;
    final curved = CurvedAnimation(
      parent: _entranceController,
      curve: interval,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
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
          padding: AppSpace.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BrandHeader(
                onHistory: () => _open(context, const HistoryScreen()),
                onSettings: () => _open(context, const SettingsScreen()),
              ),
              const SizedBox(height: AppSpace.lg),
              _entrance(
                const Interval(0.0, 0.4),
                _Greeting(configured: configured),
              ),
              const SizedBox(height: AppSpace.lg),
              _entrance(
                const Interval(0.1, 0.5),
                _HeroPanel(
                  reduceMotion: context.watch<AppController>().reduceMotion,
                  onSolve: () =>
                      _open(context, CameraScreen(mode: SolveMode.ai)),
                  onTutor: () => _open(context, const ChatScreen()),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              _entrance(
                const Interval(0.2, 0.6),
                const _CapabilityStrip(),
              ),
              const SizedBox(height: AppSpace.xxxl),
              _entrance(
                const Interval(0.35, 0.75),
                const _SectionTitle('Choose how to solve'),
              ),
              const SizedBox(height: AppSpace.lg),
              _entrance(
                const Interval(0.45, 0.85),
                _buildModeGrid(context),
              ),
              const SizedBox(height: AppSpace.xxxl),
              _entrance(
                const Interval(0.6, 0.95),
                const _SectionTitle('Your space'),
              ),
              const SizedBox(height: AppSpace.lg),
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
                  gradient: const [AppColors.aiViolet, AppColors.aiVioletLight],
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
                  gradient: const [AppColors.controlTeal, AppColors.controlTealLight],
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
                  gradient: const [AppColors.chatPink, AppColors.chatPinkLight],
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
                  gradient: const [AppColors.noAiAmber, AppColors.noAiAmberLight],
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

/// Top brand bar with a logo mark and round corner actions.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onHistory, required this.onSettings});

  final VoidCallback onHistory;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            gradient: const LinearGradient(
              colors: [AppColors.aiViolet, AppColors.controlTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                AppConstants.tagline,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'History',
          onPressed: onHistory,
          style: IconButton.styleFrom(
            backgroundColor: scheme.surfaceContainerHigh,
          ),
          icon: const Icon(Icons.history_rounded),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: onSettings,
          style: IconButton.styleFrom(
            backgroundColor: scheme.surfaceContainerHigh,
          ),
          icon: const Icon(Icons.settings_rounded),
        ),
      ],
    );
  }
}

/// Time-aware welcome line with a rotating math prompt and the AI status.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.configured});

  final bool configured;

  static const List<String> _prompts = [
    'What would you like to figure out today?',
    'Point your camera and let’s solve it together.',
    'How about checking your working with Control Mode?',
    'Ask the tutor about anything that’s been bugging you.',
    'From integrals to inequalities, I’m all ears.',
    'Pick a mode below and let’s make math click.',
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final prompt = configured
        ? _prompts[DateTime.now().day % _prompts.length]
        : _prompts[0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: text.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          configured ? prompt : 'Ready whenever you are — add an API key to go AI.',
          style: text.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Bold hero panel with two clear paths and soft animated ambience.
class _HeroPanel extends StatefulWidget {
  const _HeroPanel({
    required this.reduceMotion,
    required this.onSolve,
    required this.onTutor,
  });

  final bool reduceMotion;
  final VoidCallback onSolve;
  final VoidCallback onTutor;

  @override
  State<_HeroPanel> createState() => _HeroPanelState();
}

class _HeroPanelState extends State<_HeroPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) _float.repeat();
  }

  @override
  void didUpdateWidget(covariant _HeroPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceMotion == widget.reduceMotion) return;
    if (widget.reduceMotion) {
      _float.stop();
    } else {
      _float.repeat();
    }
  }

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
      height: 380,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(scheme.primary, const Color(0xFF14532D), 0.35)!,
            Color.lerp(scheme.primary, scheme.tertiary, 0.55)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeroChip(),
                  const Spacer(),
                  Text(
                    'Snap it.\nSolved it.',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
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
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: widget.onSolve,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: scheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.camera_alt_rounded, size: 20),
                          label: const Text('Solve'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onTutor,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.forum_rounded, size: 20),
                          label: const Text('Ask tutor'),
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

/// Material 3 [Chip] used as the hero label.
class _HeroChip extends StatelessWidget {
  const _HeroChip();

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(
        Icons.auto_awesome_rounded,
        size: 16,
        color: Colors.white,
      ),
      label: const Text('AI-powered math sidekick'),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      labelPadding: EdgeInsets.zero,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Three quick "why we exist" tiles that sit right under the hero.
class _CapabilityStrip extends StatelessWidget {
  const _CapabilityStrip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = [
      (Icons.format_list_numbered_rounded, 'Step-by-step'),
      (Icons.rate_review_rounded, 'Score your work'),
      (Icons.offline_bolt_rounded, '0 AI needed'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 34,
                color: scheme.outlineVariant,
              )
            else
              const SizedBox(width: 0),
            Expanded(
              child: Column(
                children: [
                  Icon(items[i].$1, color: scheme.primary, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    items[i].$2,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                color: const Color(0xFF166534).withValues(alpha: 0.22),
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
      final y = h * 0.45 + math.sin(x / w * math.pi * 2) * (h * 0.22);
      path.lineTo(x, y);
    }
    path.lineTo(w, h);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => oldDelegate.color != color;
}

/// Section heading with a short accent bar.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
          style: text.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

/// Tool card with a gradient icon tile and an arrow call-to-action.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.tagline,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String tagline;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const Spacer(),
              Text(
                title,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tagline,
                style: text.labelLarge?.copyWith(
                  color: gradient.first,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Spacer(),
                  Icon(
                    Icons.arrow_circle_right_rounded,
                    color: gradient.first,
                    size: 26,
                  ),
                ],
              ),
            ],
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

/// Material 3 tonal [Card] used as a quick-access tile.
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Icon(icon, color: scheme.onSecondaryContainer, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: text.labelMedium?.copyWith(
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