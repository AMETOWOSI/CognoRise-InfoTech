import 'chat_message.dart';

class SharedChat {
  const SharedChat({required this.title, required this.messages});

  final String title;
  final List<ChatMessage> messages;
}
