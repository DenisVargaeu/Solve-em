library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_dimensions.dart';
import '../../domain/entities/ai_provider.dart';
import '../state/analysis_controller.dart';
import '../state/settings_controller.dart';
import 'check_screen.dart';
import 'solution_screen.dart';

/// Shows live progress while a photo is analyzed, then routes to the result.
///
/// The analysis itself runs in [AnalysisController]; this screen only
/// subscribes to its state and navigates when it finishes.

class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({
    super.key,
    required this.mode,
    required this.imagePath,
    this.ocrEnabled = true,
    this.ocrText = '',
  });

  final SolveMode mode;
  final String imagePath;

  /// When false, the photo is sent to a multimodal model instead of running
  /// on-device OCR.
  final bool ocrEnabled;

  /// Text already extracted and confirmed by the user; skips OCR when set.
  final String ocrText;

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  bool _launched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _launch());
  }

  void _launch() {
    if (_launched) return;
    _launched = true;
    final controller = context.read<AnalysisController>();
    final settings = context.read<SettingsController>();

    final future = widget.mode == SolveMode.ai
        ? controller.analyze(
            imagePath: widget.imagePath,
            settings: settings.settings,
            ocrEnabled: widget.ocrEnabled,
            ocrText: widget.ocrText,
          )
        : controller.check(
            imagePath: widget.imagePath,
            settings: settings.settings,
            ocrEnabled: widget.ocrEnabled,
            ocrText: widget.ocrText,
          );

    future.then((problem) {
      if (!mounted || problem == null) return;
      // Replace this progress screen with the result.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => widget.mode == SolveMode.ai
              ? SolutionScreen(problem: problem)
              : CheckScreen(problem: problem),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // True centering in both axes, scrollable so the content never
        // overflows on small screens or with large text scales.
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Consumer<AnalysisController>(
                builder: (context, controller, _) {
                  if (controller.stage == AnalysisStage.error) {
                    return _buildError(context, controller);
                  }
                  return _buildProgress(context, controller);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(BuildContext context, AnalysisController controller) {
    final scheme = Theme.of(context).colorScheme;
    final message = switch (controller.stage) {
      AnalysisStage.preparing => 'Preparing…',
      AnalysisStage.readingImage => 'Reading text from the image…',
      AnalysisStage.sendingToAi =>
        widget.ocrEnabled
            ? 'Sending to the AI…'
            : 'Sending the photo to the AI…',
      AnalysisStage.formatting => 'Formatting the solution…',
      _ => 'Working…',
    };
    final icon = switch (controller.stage) {
      AnalysisStage.readingImage => Icons.document_scanner_rounded,
      AnalysisStage.sendingToAi => Icons.rocket_launch_rounded,
      AnalysisStage.formatting => Icons.auto_fix_high_rounded,
      _ => Icons.auto_awesome_rounded,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  color: scheme.primary,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              Icon(icon, size: 40, color: scheme.primary),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          widget.mode == SolveMode.ai
              ? 'Solving your problem…'
              : 'Checking your solution…',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            message,
            key: ValueKey(message),
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
          ),
        ),
        const SizedBox(height: 40),
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, AnalysisController controller) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.error_outline_rounded, size: 64, color: scheme.error),
        const SizedBox(height: 16),
        Text('Analysis failed', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          controller.errorMessage ?? 'Unknown error.',
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        if (controller.ocrText.isNotEmpty) ...[
          Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Detected text:\n${controller.ocrText}',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ],
    );
  }

  void _retry() {
    _launched = false;
    setState(() {});
    _launch();
  }
}
