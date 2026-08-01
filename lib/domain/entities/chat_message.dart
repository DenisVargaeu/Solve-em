library;

/// Who wrote a [ChatMessage].
enum ChatRole { user, assistant }

/// One turn in the math chat conversation.
class ChatMessage {
  const ChatMessage({required this.role, required this.text});

  final ChatRole role;
  final String text;
}
