library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gradient_card.dart';
import '../../domain/entities/ai_provider.dart';
import '../state/settings_controller.dart';
import 'camera_screen.dart';
import 'chat_screen.dart';
import 'history_screen.dart';
import 'no_ai/no_ai_home_screen.dart';
import 'settings_screen.dart';

/// Home screen: greeting header, the three mode cards and quick access tiles.

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final configured = settings.isConfigured;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.appName,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            Text(
              AppConstants.tagline,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => _open(context, const HistoryScreen()),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => _open(context, const SettingsScreen()),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const _GreetingCard(),
              const SizedBox(height: 16),
              _ProviderBanner(configured: configured),
              const SizedBox(height: 24),
              const _SectionHeader(
                'Choose a mode',
                Icons.dashboard_customize_rounded,
              ),
              const SizedBox(height: 12),
              GradientCard(
                title: 'AI Mode',
                subtitle:
                    'Snap a problem and get a full step-by-step solution.',
                icon: Icons.auto_awesome_rounded,
                colors: const [AppColors.aiViolet, AppColors.aiVioletLight],
                badge: 'AI-powered',
                hero: true,
                onTap: () => _open(context, CameraScreen(mode: SolveMode.ai)),
              ),
              const SizedBox(height: 14),
              GradientCard(
                title: 'Control Mode',
                subtitle: 'Check your written solution and get a score.',
                icon: Icons.fact_check_rounded,
                colors: const [
                  AppColors.controlTeal,
                  AppColors.controlTealLight,
                ],
                badge: 'Instant feedback',
                onTap: () =>
                    _open(context, CameraScreen(mode: SolveMode.control)),
              ),
              const SizedBox(height: 14),
              GradientCard(
                title: 'Chat',
                subtitle: 'Ask a friendly tutor anything — no photo needed.',
                icon: Icons.chat_rounded,
                colors: const [AppColors.chatPink, AppColors.chatPinkLight],
                badge: 'Tutor',
                onTap: () => _open(context, const ChatScreen()),
              ),
              const SizedBox(height: 14),
              GradientCard(
                title: 'No AI Mode',
                subtitle:
                    'Calculator, formulas, notes and history — fully offline.',
                icon: Icons.menu_book_rounded,
                colors: const [AppColors.noAiAmber, AppColors.noAiAmberLight],
                badge: 'Fully offline',
                onTap: () => _open(context, const NoAiHomeScreen()),
              ),
              const SizedBox(height: 24),
              const _SectionHeader('Quick access', Icons.bolt_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.chat_rounded,
                      label: 'Chat',
                      onTap: () => _open(context, const ChatScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.history_rounded,
                      label: 'History',
                      onTap: () => _open(context, const HistoryScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      onTap: () => _open(context, const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

/// Hero greeting panel with a soft gradient and feature chips.
class _GreetingCard extends StatelessWidget {
  const _GreetingCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.tertiary, 0.45)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ready to solve?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Snap a math problem and get a clear step-by-step explanation.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniChip(icon: Icons.camera_alt_rounded, label: 'Snap'),
                  _MiniChip(
                    icon: Icons.psychology_rounded,
                    label: 'AI explained',
                  ),
                  _MiniChip(
                    icon: Icons.offline_bolt_rounded,
                    label: 'Works offline',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small translucent pill inside the greeting card.
class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small section label with an icon.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.icon);

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Compact tappable tile for the quick-access row.
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary, size: 26),
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

/// Small banner that nudges the user to configure an API key when missing.
class _ProviderBanner extends StatelessWidget {
  const _ProviderBanner({required this.configured});

  final bool configured;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: configured
          ? scheme.primaryContainer.withValues(alpha: 0.5)
          : scheme.errorContainer.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              configured
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              color: configured ? scheme.primary : scheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                configured
                    ? 'Ready to analyze with ${_providerLabel(context)}'
                    : 'Add your API key in Settings to unlock AI modes.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: configured
                      ? scheme.onPrimaryContainer
                      : scheme.onErrorContainer,
                ),
              ),
            ),
            if (!configured)
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
                child: const Text('Configure'),
              ),
          ],
        ),
      ),
    );
  }

  String _providerLabel(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final model = settings.settings.model.isEmpty
        ? 'default model'
        : settings.settings.model;
    return '${settings.providerLabel} ($model)';
  }
}
