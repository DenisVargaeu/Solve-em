library;

import 'package:solveem/domain/entities/ai_settings.dart';
import 'package:solveem/domain/entities/chat_message.dart';
import 'package:solveem/domain/usecases/chat_usecase.dart';
import 'package:solveem/presentation/state/chat_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeChatUseCase extends ChatUseCase {
  _FakeChatUseCase(this.replies)
    : super(resolveGateway: (_) => throw UnimplementedError());

  final List<String> replies;
  int calls = 0;
  List<ChatMessage> lastMessages = const [];

  @override
  Future<String> call(ChatParams params) async {
    calls++;
    lastMessages = List.of(params.messages);
    return replies[(calls - 1).clamp(0, replies.length - 1)];
  }
}

void main() {
  group('ChatController', () {
    const settings = AiSettings(apiKey: 'test');

    test('appends user and assistant messages', () async {
      final useCase = _FakeChatUseCase([
        'Let\'s start with the quadratic formula.',
      ]);
      final controller = ChatController(chat: useCase);

      await controller.send(settings: settings, text: 'Explain quadratics');

      expect(controller.messages, hasLength(2));
      expect(controller.messages[0].role, ChatRole.user);
      expect(controller.messages[0].text, 'Explain quadratics');
      expect(controller.messages[1].role, ChatRole.assistant);
      expect(controller.messages[1].text, contains('quadratic formula'));
      expect(controller.busy, isFalse);
      expect(controller.error, isNull);
    });

    test('passes the full history as context', () async {
      final useCase = _FakeChatUseCase(['reply']);
      final controller = ChatController(chat: useCase);

      await controller.send(settings: settings, text: 'first');
      await controller.send(settings: settings, text: 'second');

      expect(useCase.calls, 2);
      expect(useCase.lastMessages, hasLength(3));
      expect(useCase.lastMessages.last.text, 'second');
    });

    test('ignores empty input and clears messages on clear', () async {
      final useCase = _FakeChatUseCase(['reply']);
      final controller = ChatController(chat: useCase);

      await controller.send(settings: settings, text: '   ');

      expect(useCase.calls, 0);
      expect(controller.messages, isEmpty);

      await controller.send(settings: settings, text: 'hi');
      expect(controller.messages, hasLength(2));

      controller.clear();
      expect(controller.messages, isEmpty);
    });
  });
}
