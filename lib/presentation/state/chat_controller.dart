library;

import 'package:flutter/foundation.dart';

import '../../core/errors/app_exceptions.dart';
import '../../domain/entities/ai_settings.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/chat_usecase.dart';

/// Holds the math chat conversation and talks to the AI tutor.
///
/// Messages live in memory for the session. A new chat resets them.

class ChatController extends ChangeNotifier {
  ChatController({required ChatUseCase chat}) : _chat = chat;

  final ChatUseCase _chat;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _busy = false;
  bool get busy => _busy;

  String? _error;
  String? get error => _error;

  /// Sends the user's [text] and appends the assistant's reply.
  Future<void> send({
    required AiSettings settings,
    required String text,
  }) async {
    final question = text.trim();
    if (question.isEmpty || _busy) return;

    _messages.add(ChatMessage(role: ChatRole.user, text: question));
    _error = null;
    _busy = true;
    notifyListeners();

    try {
      final reply = await _chat(
        ChatParams(settings: settings, messages: List.of(_messages)),
      );
      _messages.add(ChatMessage(role: ChatRole.assistant, text: reply.trim()));
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Clears the conversation and any error.
  void clear() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }
}
