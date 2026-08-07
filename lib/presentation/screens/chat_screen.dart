library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_dimensions.dart';
import '../../domain/entities/chat_message.dart';
import '../state/chat_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/math_text.dart';
import 'settings_screen.dart';

/// Free-form math tutor chat. Conversation stays in memory for the session.

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _lastMessageCount = context.read<ChatController>().messages.length;
    _input.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _input.removeListener(_onInputChanged);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onInputChanged() => setState(() {});

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final settings = context.read<SettingsController>().settings;
    if (!settings.isConfigured) return;

    _input.clear();
    _scrollToBottom();
    await context.read<ChatController>().send(settings: settings, text: text);
    if (mounted) {
      if (context.read<ChatController>().error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<ChatController>().error!)),
        );
      }
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final settings = context.watch<SettingsController>();
    final configured = settings.isConfigured;

    if (_lastMessageCount != chat.messages.length) {
      _lastMessageCount = chat.messages.length;
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          if (chat.messages.isNotEmpty)
            IconButton(
              tooltip: 'New chat',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () {
                context.read<ChatController>().clear();
                _input.clear();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!configured) _NotConfiguredBanner(onConfigure: _openSettings),
            Expanded(
              child: chat.messages.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: chat.messages.length + (chat.busy ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= chat.messages.length) {
                          return const _TypingBubble();
                        }
                        return _MessageBubble(
                          message: chat.messages[i],
                          index: i,
                        );
                      },
                    ),
            ),
            _InputBar(
              controller: _input,
              enabled: configured && !chat.busy,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }
}

/// One chat bubble, right-aligned for the user and left for the assistant.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.index});

  final ChatMessage message;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.role == ChatRole.user;

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? scheme.primary : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
      ),
      child: MathText(
        message.text,
        style: TextStyle(
          fontSize: 15,
          height: 1.45,
          color: isUser ? scheme.onPrimary : scheme.onSurface,
        ),
      ),
    );

    final row = isUser
        ? [const SizedBox(width: 40), Expanded(child: bubble)]
        : [
            _Avatar(icon: isUser ? Icons.person_rounded : Icons.school_rounded),
            const SizedBox(width: 8),
            Expanded(child: bubble),
          ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: row),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
    );
  }
}

/// Three animated dots shown while the tutor is typing.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Avatar(icon: Icons.school_rounded),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.all(Radius.circular(18)),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final phase = ((t * 3) - i) % 1.0;
                    final opacity = phase < 0.3
                        ? 0.3 + 0.7 * (phase / 0.3)
                        : 1.0 - phase;
                    return Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(
                          alpha: opacity.clamp(0.3, 1.0),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly prompt shown before the first message.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_rounded, size: 56, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'Ask me anything about math',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Example: "Explain how to solve a quadratic equation"',
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Text field plus send button.
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: enabled
                    ? 'Ask a math question…'
                    : 'Add your API key first',
                filled: true,
                fillColor: scheme.surfaceContainerHigh,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            width: 48,
            child: IconButton.filled(
              tooltip: 'Send',
              onPressed: enabled && controller.text.trim().isNotEmpty
                  ? onSend
                  : null,
              icon: const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact banner shown when no API key is configured yet.
class _NotConfiguredBanner extends StatelessWidget {
  const _NotConfiguredBanner({required this.onConfigure});

  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: scheme.error),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Add your API key in Settings to start chatting.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(onPressed: onConfigure, child: const Text('Settings')),
          ],
        ),
      ),
    );
  }
}
