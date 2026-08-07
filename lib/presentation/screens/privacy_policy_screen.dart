library;

import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';

/// In-app Privacy Policy page, reachable from Settings.

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String lastUpdated = '2 August 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: AppSpace.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Last updated: $lastUpdated',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Solve 'em is a math learning companion. It helps you photograph "
              'a math problem and get step-by-step solutions, check your own '
              'written work, chat with a tutor, and work offline with a '
              'calculator, formula library and notes.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            const _PolicySection(
              title: 'In short',
              body:
                  'The app has no accounts and does not collect your name, '
                  'email or phone. Your API key never leaves your device. '
                  'Photos and math content are sent only to your chosen AI '
                  'provider, and only when you actively analyze or check a '
                  'problem. History and notes are stored locally on your '
                  'device, and you can delete all data at any time.',
            ),
            const _PolicySection(
              title: 'AI API key',
              body:
                  'To use the AI-powered modes you provide an API key for a '
                  'provider of your choice (OpenAI-compatible endpoints, '
                  'Google Gemini, OpenRouter or NVIDIA NIM). The key is stored '
                  'locally on your device and is used only to authenticate '
                  'requests to that provider. It is never logged, uploaded '
                  'elsewhere or shared with any party other than the provider '
                  'you configured.',
            ),
            const _PolicySection(
              title: 'Photos and math content',
              body:
                  'When you use AI Mode or Control Mode, the app may process a '
                  'photo you take. Text in the image is read using on-device '
                  'OCR and does not leave your device. When you analyze a '
                  'problem, the image or extracted text is sent to the AI '
                  'provider you configured so it can generate a solution or '
                  'check your work. This transfer is subject to that '
                  "provider's own privacy and data policies.",
            ),
            const _PolicySection(
              title: 'Local data',
              body:
                  'Solutions you save, your chat history, math notes and app '
                  'settings are stored locally on your device. The app does '
                  'not upload this data to any server operated by the '
                  'developer, and it does not include analytics or advertising '
                  'SDKs that collect personal data.',
            ),
            const _PolicySection(
              title: 'Data retention and deletion',
              body:
                  'Data stored locally stays on your device until you delete '
                  'it. You can clear your API key, clear your history and '
                  'delete your notes at any time from the Settings screen. '
                  'Uninstalling the app removes all locally stored data.',
            ),
            const _PolicySection(
              title: 'Changes to this policy',
              body:
                  'We may update this Privacy Policy from time to time. Any '
                  'changes will be reflected by updating the "Last updated" '
                  'date at the top of this page.',
            ),
          ],
        ),
      ),
    );
  }
}

/// One titled block of the policy.
class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: text.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
