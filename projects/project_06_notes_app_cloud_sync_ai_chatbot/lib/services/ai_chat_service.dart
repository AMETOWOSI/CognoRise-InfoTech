import 'package:firebase_ai/firebase_ai.dart';

import '../models/chat_message.dart';

abstract interface class AiChatConversation {
  Future<String> sendMessage(String message);
}

abstract interface class AiChatService {
  AiChatConversation createConversation({List<ChatMessage> history = const []});
}

class FirebaseAiChatService implements AiChatService {
  const FirebaseAiChatService();

  static const _maxContextMessages = 24;

  @override
  AiChatConversation createConversation({
    List<ChatMessage> history = const [],
  }) => _FirebaseAiChatConversation(
    history.length <= _maxContextMessages
        ? history
        : history.sublist(history.length - _maxContextMessages),
  );
}

class _FirebaseAiChatConversation implements AiChatConversation {
  _FirebaseAiChatConversation(List<ChatMessage> history)
    : _chat = FirebaseAI.googleAI()
          .generativeModel(model: 'gemini-3.8-flash')
          .startChat(
            history: history
                .map(
                  (message) => Content(
                    message.role == ChatMessageRole.user ? 'user' : 'model',
                    [TextPart(message.text)],
                  ),
                )
                .toList(growable: false),
          );

  final ChatSession _chat;

  @override
  Future<String> sendMessage(String message) async {
    final response = await _chat.sendMessage(Content.text(message));
    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw const EmptyAiResponseException();
    }
    return text;
  }
}

class EmptyAiResponseException implements Exception {
  const EmptyAiResponseException();
}
