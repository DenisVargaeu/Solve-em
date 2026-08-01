library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../data/datasources/remote/ai/ai_gateway_factory.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/ai_settings.dart';
import '../di/app_dependencies.dart';
import '../state/app_controller.dart';
import '../state/history_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/model_picker_sheet.dart';

/// Settings screen: AI provider configuration, API key, theme, privacy.

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  final _baseUrlController = TextEditingController();

  bool _obscureKey = true;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _syncFromSettings(context.read<SettingsController>());
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  void _syncFromSettings(SettingsController controller) {
    _apiKeyController.text = controller.settings.apiKey;
    _modelController.text = controller.settings.model;
    _baseUrlController.text = controller.settings.baseUrl;
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();
    final appController = context.watch<AppController>();
    final settings = settingsController.settings;

    if (!settingsController.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _SectionLabel('AI provider'),
          const SizedBox(height: 8),

          // ── Provider selector ───────────────────────────────────────────
          SegmentedButton<AiProvider>(
            segments: AiProvider.values
                .map(
                  (p) => ButtonSegment(
                    value: p,
                    label: Text(switch (p) {
                      AiProvider.openai => 'OpenAI',
                      AiProvider.gemini => 'Gemini',
                      AiProvider.openrouter => 'OpenRouter',
                      AiProvider.nvidia => 'NVIDIA',
                    }),
                  ),
                )
                .toList(),
            selected: {settings.provider},
            onSelectionChanged: (selection) {
              final provider = selection.first;
              final model =
                  AppConstants.defaultModelByProvider[provider.id] ?? '';
              settingsController.update(
                settings.copyWith(
                  provider: provider,
                  model: model,
                  baseUrl: switch (provider) {
                    AiProvider.openai => AppConstants.defaultBaseUrl,
                    AiProvider.openrouter => AppConstants.openRouterBaseUrl,
                    AiProvider.nvidia => AppConstants.nvidiaBaseUrl,
                    AiProvider.gemini => '',
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'API keys are stored only on your device. Model limits, pricing '
            'and privacy policies depend on your provider.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // ── API key ─────────────────────────────────────────────────────
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'API key',
              hintText: 'sk-…',
              prefixIcon: const Icon(Icons.key_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureKey
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
            onChanged: (_) => _markDirty(settingsController),
          ),
          const SizedBox(height: 12),

          // ── Model ───────────────────────────────────────────────────────
          TextField(
            controller: _modelController,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Model',
              hintText: 'e.g. gpt-4o-mini, gemini-2.0-flash',
              prefixIcon: Icon(Icons.smart_toy_rounded),
            ),
            onChanged: (_) => _markDirty(settingsController),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _openModelPicker(settingsController),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Browse available models'),
            ),
          ),
          const SizedBox(height: 4),

          // ── Base URL (OpenAI-compatible) ────────────────────────────────
          if (settings.provider == AiProvider.openai ||
              settings.provider == AiProvider.openrouter ||
              settings.provider == AiProvider.nvidia) ...[
            TextField(
              controller: _baseUrlController,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Base URL (advanced)',
                hintText: 'https://api.openai.com/v1',
                prefixIcon: Icon(Icons.link_rounded),
              ),
              onChanged: (_) => _markDirty(settingsController),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _testing ? null : () => _save(settingsController),
                  icon: _testing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_testing ? 'Saving…' : 'Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing
                      ? null
                      : () => _testConnection(settingsController),
                  icon: const Icon(Icons.wifi_tethering_rounded),
                  label: const Text('Test'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Divider(),
          const SizedBox(height: 8),
          const _SectionLabel('Appearance'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.brightness_6_rounded),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Theme')),
                  DropdownButton<ThemeMode>(
                    value: appController.themeMode,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                    ],
                    onChanged: (mode) {
                      if (mode != null) appController.setThemeMode(mode);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.document_scanner_rounded),
              title: const Text('On-device OCR'),
              subtitle: Text(
                settingsController.ocrEnabled
                    ? 'Reads text from photos and sends only the text to the AI.'
                    : 'Sends the photo straight to a multimodal model (no OCR).',
              ),
              value: settingsController.ocrEnabled,
              onChanged: settingsController.setOcrEnabled,
            ),
          ),
          if (!settingsController.ocrEnabled) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Pick a vision-capable model — use the "Vision" filter when '
                'browsing available models.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          const Divider(),
          const SizedBox(height: 8),
          const _SectionLabel('Privacy & data'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Your API key never leaves this device. Photos and '
                          'solutions are sent only to your chosen AI provider '
                          'when you analyze a problem, and results are stored '
                          'locally in the app.',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _clearKey(settingsController),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Clear API key'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_sweep_rounded),
              title: const Text('Clear history'),
              subtitle: const Text('Delete every saved problem and solution.'),
              onTap: () => _clearHistory(context),
            ),
          ),
          const SizedBox(height: 24),

          const Divider(),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${AppConstants.appName} v1.0.0\nA math learning companion. '
              'Use your own AI API key.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _markDirty(SettingsController controller) {
    controller.update(_draft(controller));
  }

  AiSettings _draft(SettingsController controller) {
    final current = controller.settings;
    return AiSettings(
      provider: current.provider,
      apiKey: _apiKeyController.text,
      model: _modelController.text.trim().isEmpty
          ? AppConstants.defaultModelByProvider[current.provider.id] ?? ''
          : _modelController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
    );
  }

  Future<void> _save(SettingsController controller) async {
    await controller.save(_draft(controller));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  Future<void> _openModelPicker(SettingsController controller) async {
    final settings = _draft(controller);
    if (!settings.isConfigured && settings.provider != AiProvider.openrouter) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter an API key first')));
      return;
    }
    final deps = context.read<AppDependencies>();
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ModelPickerSheet(
        providerLabel: settings.provider.label,
        fetchModels: () => deps.listModels(settings),
      ),
    );
    if (selected == null || !mounted) return;
    _modelController.text = selected;
    _markDirty(controller);
  }

  Future<void> _testConnection(SettingsController controller) async {
    final settings = _draft(controller);
    if (!settings.isConfigured) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter an API key first')));
      return;
    }
    setState(() => _testing = true);
    try {
      final deps = context.read<AppDependencies>();
      final tester = AiConnectionTester(deps.gatewayFor(settings));
      await tester.testConnection(settings);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Connection OK')));
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _clearKey(SettingsController controller) async {
    _apiKeyController.clear();
    await controller.save(_draft(controller).copyWith(apiKey: ''));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('API key cleared')));
  }

  Future<void> _clearHistory(BuildContext context) async {
    final history = context.read<HistoryController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
          'This deletes every saved problem and solution from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await history.clear();
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
