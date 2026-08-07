library;

import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';
import '../../domain/entities/ai_provider.dart';
import 'analyzing_screen.dart';

/// Lets the user review (and fix) the text OCR detected before it is sent to
/// the AI. When nothing was detected, the photo can be handed to a multimodal
/// model instead.

class ConfirmTextScreen extends StatefulWidget {
  const ConfirmTextScreen({
    super.key,
    required this.mode,
    required this.imagePath,
    required this.initialText,
  });

  final SolveMode mode;
  final String imagePath;
  final String initialText;

  @override
  State<ConfirmTextScreen> createState() => _ConfirmTextScreenState();
}

class _ConfirmTextScreenState extends State<ConfirmTextScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => AnalyzingScreen(
          mode: widget.mode,
          imagePath: widget.imagePath,
          ocrText: _controller.text.trim(),
        ),
      ),
    );
  }

  void _sendPhotoToAi() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => AnalyzingScreen(
          mode: widget.mode,
          imagePath: widget.imagePath,
          ocrEnabled: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final detectedNothing = widget.initialText.trim().isEmpty;
    final isAi = widget.mode == SolveMode.ai;

    return Scaffold(
      appBar: AppBar(title: const Text('Check the text')),
      body: ListView(
        padding: AppSpace.screen,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.document_scanner_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    detectedNothing
                        ? 'No text was detected. Type the ${isAi ? 'problem' : 'solution'} below, '
                              'or send the photo to a multimodal model instead.'
                        : 'This is what was read from your photo. Fix any mistakes '
                              'before it is sent to the AI.',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 10,
            minLines: 4,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: isAi ? 'Problem text' : 'Your solution',
              hintText: detectedNothing
                  ? 'Start typing…'
                  : 'Edit the detected text if needed…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _continue,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Continue'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _sendPhotoToAi,
            icon: const Icon(Icons.image_search_rounded),
            label: const Text('Send the photo to the AI instead'),
            style: OutlinedButton.styleFrom(foregroundColor: scheme.tertiary),
          ),
          const SizedBox(height: 8),
          Text(
            'Sending the photo directly requires a multimodal model that '
            'accepts image input.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
