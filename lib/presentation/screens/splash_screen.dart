library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import 'home_screen.dart';

/// Startup sequence: a short "Made by Denis Varga" credit splash, then the
/// branded splash with the app logo, then the home screen.

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _showLogo = false;

  static const Duration _creditDuration = Duration(milliseconds: 1800);
  static const Duration _logoDuration = Duration(milliseconds: 2200);

  @override
  void initState() {
    super.initState();
    _timer = Timer(_creditDuration, () {
      if (!mounted) return;
      setState(() => _showLogo = true);
      _timer = Timer(_logoDuration, _goHome);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _showLogo
          ? const _LogoSplash(key: ValueKey('logo'))
          : const _CreditSplash(key: ValueKey('credit')),
    );
  }
}

/// First stage: "Made by Denis Varga · denisvarga.eu".
class _CreditSplash extends StatelessWidget {
  const _CreditSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return _BrandBackground(
      child: Stack(
        children: [
          // Truly centered credit block.
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Made by',
                  style: TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Denis Varga',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'denisvarga.eu',
                  style: TextStyle(
                    color: Color(0xE6FFFFFF),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Footer pinned to the bottom edge.
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '${AppConstants.appName} · ${AppConstants.tagline}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0x80FFFFFF),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Second stage: app name with the brand logo.
class _LogoSplash extends StatelessWidget {
  const _LogoSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return _BrandBackground(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppConstants.tagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared branded gradient background for both splash stages.
class _BrandBackground extends StatelessWidget {
  const _BrandBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.aiViolet, Color(0xFF16A34A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}
