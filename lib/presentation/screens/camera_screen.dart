library;

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/ai_provider.dart';
import '../di/app_dependencies.dart';
import '../state/settings_controller.dart';
import 'analyzing_screen.dart';
import 'confirm_text_screen.dart';
import 'settings_screen.dart';

/// Camera / gallery capture screen.
///
/// Flow: take photo (or pick from gallery) → crop → preview → analyze.
/// [mode] decides whether the captured photo is run through AI Mode or
/// Control Mode.

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.mode});

  final SolveMode mode;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

enum _Phase { camera, preview }

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  CameraController? _camera;
  bool _cameraReady = false;
  bool _cameraBusy = false;
  String? _cameraError;
  bool _torchOn = false;

  _Phase _phase = _Phase.camera;
  String? _imagePath;

  bool get _web => kIsWeb;

  @override
  void initState() {
    super.initState();
    if (!_web) _initCamera();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    setState(() => _cameraReady = false);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'No camera found on this device.');
      }
      final description = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        description,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _camera = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() => _cameraReady = true);
    } on CameraException catch (e) {
      _onCameraError(e.description ?? e.code);
    } catch (_) {
      _onCameraError('Could not start the camera.');
    }
  }

  void _onCameraError(String message) {
    if (!mounted) return;
    setState(() => _cameraError = message);
  }

  /// Captures a photo with the live camera.
  Future<void> _takePhoto() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized || _cameraBusy) return;
    setState(() => _cameraBusy = true);
    try {
      final file = await camera.takePicture();
      await _processImage(file.path);
    } on CameraException catch (e) {
      _showSnack('Could not take photo: ${e.description ?? e.code}');
    } catch (_) {
      _showSnack('Could not take photo.');
    } finally {
      if (mounted) setState(() => _cameraBusy = false);
    }
  }

  /// Picks an image from the gallery.
  Future<void> _pickFromGallery() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 95,
      );
      if (file == null) return;
      await _processImage(file.path);
    } catch (_) {
      _showSnack('Could not open the gallery.');
    }
  }

  /// Runs the crop UI, then switches to the preview phase.
  Future<void> _processImage(String path) async {
    if (!mounted) return;
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: path,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop problem',
            toolbarColor: Theme.of(context).colorScheme.surface,
            toolbarWidgetColor: Theme.of(context).colorScheme.onSurface,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
            aspectRatioPresets: const [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(title: 'Crop problem', minimumAspectRatio: 0.1),
        ],
      );
      if (cropped == null || !mounted) return; // user cancelled
      setState(() {
        _imagePath = cropped.path;
        _phase = _Phase.preview;
      });
    } catch (_) {
      _showSnack('Could not crop the image.');
    }
  }

  void _toggleTorch() async {
    final camera = _camera;
    if (camera == null) return;
    final next = !_torchOn;
    try {
      await camera.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      setState(() => _torchOn = next);
    } catch (_) {
      _showSnack('Flash is not available on this camera.');
    }
  }

  void _flipCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) {
        _showSnack('Only one camera is available.');
        return;
      }
      final currentLens = _camera?.description.lensDirection;
      final next = cameras.firstWhere(
        (c) => c.lensDirection != currentLens,
        orElse: () => cameras.first,
      );
      await _camera?.dispose();
      final controller = CameraController(
        next,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _camera = controller;
      await controller.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      _showSnack('Could not switch camera.');
    }
  }

  Future<void> _analyze() async {
    final path = _imagePath;
    if (path == null) return;
    final settings = context.read<SettingsController>();

    if (!settings.isConfigured) {
      _showSnack(
        'Add your API key first.',
        actionLabel: 'Settings',
        onAction: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
          );
        },
      );
      return;
    }

    if (!settings.ocrEnabled) {
      // OCR is off: hand the photo directly to a multimodal model.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => AnalyzingScreen(
            mode: widget.mode,
            imagePath: path,
            ocrEnabled: false,
          ),
        ),
      );
      return;
    }

    // OCR first, then let the user confirm the detected text before the AI.
    _showOcrLoading();
    String text = '';
    try {
      final deps = context.read<AppDependencies>();
      text = (await deps.ocrGateway.extractText(path)).trim();
    } catch (_) {
      text = '';
    }
    if (!mounted) return;
    Navigator.of(context).pop(); // close the loading dialog
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ConfirmTextScreen(
          mode: widget.mode,
          imagePath: path,
          initialText: text,
        ),
      ),
    );
  }

  void _showOcrLoading() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(width: 16),
              Expanded(child: Text('Reading text from the photo…')),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: onAction == null
            ? null
            : SnackBarAction(label: actionLabel!, onPressed: onAction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == SolveMode.ai ? 'AI Mode' : 'Control Mode'),
      ),
      body: switch (_phase) {
        _Phase.preview => _buildPreview(),
        _ => _buildCapture(),
      },
    );
  }

  // ── Preview (photo taken, ready to analyze) ─────────────────────────────

  Widget _buildPreview() {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  // ignore: avoid_dynamic_calls
                  File(_imagePath!),
                  fit: BoxFit.contain,
                ),
                if (widget.mode == SolveMode.control)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates_rounded,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Make sure your handwritten solution is in the frame and readable.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _phase = _Phase.camera),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _analyze,
                    icon: const Icon(Icons.auto_fix_high_rounded),
                    label: Text(
                      widget.mode == SolveMode.ai
                          ? 'Solve it'
                          : 'Check my work',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Capture (camera / gallery) ──────────────────────────────────────────

  Widget _buildCapture() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Camera'),
            Tab(text: 'Gallery'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildCameraTab(), _buildGalleryTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraTab() {
    if (_web) {
      return Center(
        child: FilledButton.icon(
          onPressed: _pickFromGallery,
          icon: const Icon(Icons.photo_library_rounded),
          label: const Text('Choose an image'),
        ),
      );
    }
    if (_cameraError != null) {
      return _CameraErrorView(message: _cameraError!, onRetry: _initCamera);
    }
    if (!_cameraReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Positioned.fill(
          child: _camera!.value.isInitialized
              ? CameraPreview(_camera!)
              : Container(color: Colors.black),
        ),
        // Top controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _RoundIconButton(
                  icon: _torchOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  active: _torchOn,
                  onTap: _toggleTorch,
                ),
                const SizedBox(width: 12),
                _RoundIconButton(
                  icon: Icons.cameraswitch_rounded,
                  onTap: _flipCamera,
                ),
              ],
            ),
          ),
        ),
        // Shutter
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: _ShutterButton(busy: _cameraBusy, onTap: _takePhoto),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Pick a photo of the problem',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You can also use a screenshot of an online problem.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('Choose image'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private building blocks ──────────────────────────────────────────────

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, this.onTap, this.active = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: active ? Colors.amber : Colors.white),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onTap, required this.busy});

  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          color: busy ? Colors.white70 : Colors.transparent,
        ),
        padding: const EdgeInsets.all(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: busy ? Colors.white : primary,
          ),
        ),
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_photography_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
