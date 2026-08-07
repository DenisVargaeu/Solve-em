library;

import 'package:flutter/material.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/theme/app_dimensions.dart';

/// Lets the user pick a model from the provider's advertised model catalog.
///
/// Opens as a modal bottom sheet. [fetchModels] runs once on open and the
/// sheet shows loading / error (with retry) / results. A search field and
/// "Math" / "Vision" filters narrow the list to models suited for math work
/// and/or multimodal (image input) use.

class ModelPickerSheet extends StatefulWidget {
  const ModelPickerSheet({
    super.key,
    required this.fetchModels,
    required this.providerLabel,
  });

  /// Fetches the provider's available model ids (uses the current settings).
  final Future<List<String>> Function() fetchModels;

  /// Provider name shown in the header (e.g. "NVIDIA NIM").
  final String providerLabel;

  @override
  State<ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<ModelPickerSheet> {
  late Future<List<String>> _future;
  final _search = TextEditingController();
  String _query = '';
  bool _mathOnly = false;
  bool _visionOnly = false;

  @override
  void initState() {
    super.initState();
    _future = widget.fetchModels();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Heuristic for models that are strong at math / step-by-step reasoning.
  static bool _isMathModel(String id) {
    final n = id.toLowerCase();
    const keywords = [
      'math',
      'o1',
      'o3',
      'o4',
      'reason',
      'deepseek',
      'qwen',
      'phi',
      'glm',
      'kimi',
      'nemotron',
      'gpt',
    ];
    return keywords.any(n.contains);
  }

  /// Heuristic for models that accept image input (multimodal).
  static bool _isMultimodalModel(String id) {
    final n = id.toLowerCase();
    const keywords = [
      'vl',
      'vision',
      'visual',
      'multimodal',
      'omni',
      'llava',
      'cogvlm',
      'internvl',
      'pixtral',
      'claude',
      'gemini',
      '4o',
      '4.1',
      'flash',
      'image',
    ];
    return keywords.any(n.contains);
  }

  List<String> _visible(List<String> models) {
    final q = _query.trim().toLowerCase();
    final filtered = models.where((m) {
      final matchesQuery = q.isEmpty || m.toLowerCase().contains(q);
      final matchesMath = !_mathOnly || _isMathModel(m);
      final matchesVision = !_visionOnly || _isMultimodalModel(m);
      return matchesQuery && matchesMath && matchesVision;
    }).toList();

    if (_mathOnly) return filtered..sort(_compare);
    // Pin math-suitable models first, then alphabetical order.
    filtered.sort((a, b) {
      final ma = _isMathModel(a);
      final mb = _isMathModel(b);
      if (ma != mb) return ma ? -1 : 1;
      return _compare(a, b);
    });
    return filtered;
  }

  int _compare(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());

  String _errorText(Object? error) =>
      error is AppException ? error.message : '$error';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            0,
            AppSpace.lg,
            AppSpace.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.smart_toy_rounded, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Choose a model · ${widget.providerLabel}',
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
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search models…',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: !_mathOnly && !_visionOnly,
                    onSelected: (_) => setState(() {
                      _mathOnly = false;
                      _visionOnly = false;
                    }),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Math'),
                    selected: _mathOnly,
                    onSelected: (sel) => setState(() => _mathOnly = !_mathOnly),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Vision'),
                    selected: _visionOnly,
                    onSelected: (sel) =>
                        setState(() => _visionOnly = !_visionOnly),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                size: 40,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Could not load models.\n'
                                '${_errorText(snapshot.error)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.tonalIcon(
                                onPressed: () => setState(() {
                                  _future = widget.fetchModels();
                                }),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final models = _visible(snapshot.data ?? const []);
                    if (models.isEmpty) {
                      return const Center(child: Text('No matching models.'));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: models.length,
                      itemBuilder: (context, index) {
                        final model = models[index];
                        final math = _isMathModel(model);
                        final vision = _isMultimodalModel(model);
                        final IconData icon;
                        final String? subtitle;
                        if (math && vision) {
                          icon = Icons.smart_display_rounded;
                          subtitle = 'Math + Vision';
                        } else if (math) {
                          icon = Icons.calculate_rounded;
                          subtitle = 'Good for math';
                        } else if (vision) {
                          icon = Icons.image_search_rounded;
                          subtitle = 'Accepts photos';
                        } else {
                          icon = Icons.model_training_rounded;
                          subtitle = null;
                        }
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            icon,
                            size: 20,
                            color: (math || vision) ? scheme.tertiary : null,
                          ),
                          title: Text(
                            model,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: subtitle == null
                              ? null
                              : Text(
                                  subtitle,
                                  style: const TextStyle(fontSize: 12),
                                ),
                          onTap: () => Navigator.of(context).pop(model),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
