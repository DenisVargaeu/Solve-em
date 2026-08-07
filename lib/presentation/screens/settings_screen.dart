library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../data/datasources/remote/ai/ai_gateway_factory.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/ai_settings.dart';
import '../../domain/entities/response_language.dart';
import '../di/app_dependencies.dart';
import '../state/app_controller.dart';
import '../state/history_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/model_picker_sheet.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';

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
  final _timeoutController = TextEditingController();
  final _promptController = TextEditingController();

  bool _obscureKey = true;
  bool _testing = false;
  bool _advancedExpanded = false;

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
    _timeoutController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _syncFromSettings(SettingsController controller) {
    _apiKeyController.text = controller.settings.apiKey;
    _modelController.text = controller.settings.model;
    _baseUrlController.text = controller.settings.baseUrl;
    _timeoutController.text = controller.settings.requestTimeout.toString();
    _promptController.text = controller.settings.customInstruction;
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
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            tooltip: 'About',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _AppHeader(),
          const SizedBox(height: 24),

          // ── AI provider ─────────────────────────────────────────────────
          const _SectionTitle('AI provider', Icons.auto_awesome_rounded),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<AiProvider>(
                    showSelectedIcon: false,
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
                            AiProvider.openrouter =>
                              AppConstants.openRouterBaseUrl,
                            AiProvider.nvidia => AppConstants.nvidiaBaseUrl,
                            AiProvider.gemini => '',
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'API keys are stored only on your device. Model limits, '
                    'pricing and privacy policies depend on your provider.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Credentials ─────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                    onChanged: (_) => _markDirty(settingsController),
                  ),
                  const SizedBox(height: 12),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _openModelPicker(settingsController),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Browse available models'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Advanced options ─────────────────────────────────────────────
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              leading: const Icon(Icons.tune_rounded),
              title: const Text(
                'Advanced options',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Base URL and request timeout for your provider.',
              ),
              initiallyExpanded: _advancedExpanded,
              onExpansionChanged: (expanded) =>
                  setState(() => _advancedExpanded = expanded),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      if (settings.provider == AiProvider.openai ||
                          settings.provider == AiProvider.openrouter ||
                          settings.provider == AiProvider.nvidia) ...[
                        TextField(
                          controller: _baseUrlController,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Base URL',
                            hintText: 'https://api.openai.com/v1',
                            prefixIcon: Icon(Icons.link_rounded),
                          ),
                          onChanged: (_) => _markDirty(settingsController),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                          controller: _timeoutController,
                          autocorrect: false,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Request timeout (seconds)',
                            helperText: 'Default is 60 s. Between 10 and 600.',
                            prefixIcon: Icon(Icons.timer_outlined),
                          ),
                          onChanged: (_) => _markDirty(settingsController),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _promptController,
                          maxLines: 4,
                          maxLength: 1000,
                          decoration: const InputDecoration(
                            labelText: 'Custom AI instruction (system prompt)',
                            hintText: 'e.g. Always show two solving methods…',
                            prefixIcon: Icon(Icons.tune_rounded),
                            alignLabelWithHint: true,
                          ),
                          onChanged: (_) => _markDirty(settingsController),
                        ),
                      ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Save / Test ─────────────────────────────────────────────────
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
          const SizedBox(height: 28),

          // ── Response language ───────────────────────────────────────────
          const _SectionTitle('Response language', Icons.translate_rounded),
          const SizedBox(height: 12),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: const Icon(Icons.translate_rounded),
                  title: const Text('AI answers in'),
                  subtitle: Text(
                    '${settings.responseLanguage.displayName} · '
                    '${settings.responseLanguage.label}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickResponseLanguage(
                    settingsController,
                    settings,
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Text(
                    'The AI writes its steps, hints, feedback and chat replies '
                    'in the language you pick. More languages are coming soon.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Appearance ──────────────────────────────────────────────────
          const _SectionTitle('Appearance', Icons.palette_outlined),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
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
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.brightness_6_rounded),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Theme',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: SegmentedButton<ThemeMode>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text('System'),
                                icon: Icon(
                                  Icons.brightness_auto_rounded,
                                  size: 18,
                                ),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text('Light'),
                                icon: Icon(Icons.light_mode_rounded, size: 18),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text('Dark'),
                                icon: Icon(Icons.dark_mode_rounded, size: 18),
                              ),
                            ],
                            selected: {appController.themeMode},
                            onSelectionChanged: (selection) {
                              appController.setThemeMode(selection.first);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.text_fields_rounded),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Text size',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: SegmentedButton<double>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(value: 0.85, label: Text('Small')),
                              ButtonSegment(value: 1.0, label: Text('Default')),
                              ButtonSegment(value: 1.15, label: Text('Large')),
                            ],
                            selected: {appController.textScale},
                            onSelectionChanged: (selection) {
                              appController.setTextScale(selection.first);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.motion_photos_off_rounded),
                  title: const Text('Reduce motion'),
                  subtitle: const Text(
                    'Turn off decorative animations and motion effects.',
                  ),
                  value: appController.reduceMotion,
                  onChanged: appController.setReduceMotion,
                ),
              ],
            ),
          ),
          if (!settingsController.ocrEnabled) ...[
            const SizedBox(height: 8),
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
          const SizedBox(height: 28),

          // ── Privacy & data ──────────────────────────────────────────────
          const _SectionTitle('Privacy & data', Icons.security_rounded),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Clear API key'),
                  subtitle: const Text(
                    'Remove your stored key. You must enter a new one to use AI modes.',
                  ),
                  onTap: () => _clearKey(settingsController),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_rounded),
                  title: const Text('Clear history'),
                  subtitle: const Text('Delete every saved problem and solution.'),
                  onTap: () => _clearHistory(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.policy_rounded),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('How the app handles your data.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Center(
            child: Column(
              children: [
                Text(
                  '${AppConstants.appName} v${AppConstants.appVersion}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'A math learning companion. Use your own AI API key.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
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
      responseLanguage: current.responseLanguage,
      requestTimeout: _parseTimeout(),
      customInstruction: _promptController.text,
    );
  }

  int _parseTimeout() {
    final value = int.tryParse(_timeoutController.text.trim());
    if (value == null || value < 10) return AppConstants.defaultRequestTimeout;
    return value > 600 ? 600 : value;
  }

  Future<void> _save(SettingsController controller) async {
    await controller.save(_draft(controller));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  Future<void> _pickResponseLanguage(
    SettingsController controller,
    AiSettings settings,
  ) async {
    final selected = await showModalBottomSheet<ResponseLanguage>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => LanguagePickerSheet(current: settings.responseLanguage),
    );
    if (selected == null || !mounted) return;
    controller.update(settings.copyWith(responseLanguage: selected));
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear API key?'),
        content: const Text(
          'The key will be removed from this device. You will need to enter '
          'a new one to use the AI modes.',
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
    if (confirmed != true || !mounted) return;
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

/// Compact gradient header with the app identity.
class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(scheme.primary, const Color(0xFF14532D), 0.35)!,
            Color.lerp(scheme.primary, scheme.tertiary, 0.55)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calculate_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppConstants.tagline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'v${AppConstants.appVersion}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// M3-style section heading with an accent bar and icon.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.icon);

  final String title;
  final IconData icon;

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
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 6),
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

/// Searchable bottom sheet for picking an AI response language.
class LanguagePickerSheet extends StatefulWidget {
  const LanguagePickerSheet({super.key, required this.current});

  /// The currently selected language, highlighted in the list.
  final ResponseLanguage current;

  @override
  State<LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<LanguagePickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  ResponseLanguage get _current => widget.current;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ResponseLanguage> get _visible {
    final q = _query.trim().toLowerCase();
    final languages = ResponseLanguage.values.toList();
    if (q.isEmpty) return languages;
    return languages.where((l) {
      final hay = '${l.label} ${l.code} ${l.displayName}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.translate_rounded, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI response language',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _search,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search languages…',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final lang in _visible)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.language_rounded, size: 20),
                      title: Text(lang.displayName),
                      subtitle: Text(lang.label),
                      trailing: lang == _current
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () => Navigator.of(context).pop(lang),
                    ),
                ],
              ),
            ),
            if (_visible.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No matching languages.')),
              ),
          ],
        ),
      ),
    );
  }
}
