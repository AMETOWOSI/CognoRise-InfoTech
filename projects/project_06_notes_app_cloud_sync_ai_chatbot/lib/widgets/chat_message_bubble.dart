import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatMessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(
                      colors: [AppColors.blue, AppColors.deepBlue],
                    )
                  : null,
              color: isUser ? null : AppColors.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 6),
                bottomRight: Radius.circular(isUser ? 6 : 20),
              ),
              border: isUser
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.9)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8299C9).withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(4, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: SelectableText(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.ink,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
