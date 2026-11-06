enum ChatMessageRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.role,
    required this.createdAt,
  });

  final String text;
  final ChatMessageRole role;
  final DateTime createdAt;
}
