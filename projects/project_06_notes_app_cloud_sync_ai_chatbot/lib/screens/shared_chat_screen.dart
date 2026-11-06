import 'package:flutter/material.dart';

import '../models/shared_chat.dart';
import '../services/chat_history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/chat_message_bubble.dart';

class SharedChatScreen extends StatelessWidget {
  const SharedChatScreen({
    super.key,
    required this.shareId,
    required this.reader,
  });

  final String shareId;
  final SharedChatReader reader;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Shared conversation')),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: FutureBuilder<SharedChat>(
            future: reader.loadSharedChat(shareId),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.blue),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'This shared conversation is unavailable. The link may '
                      'be invalid or have been revoked.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.mutedInk),
                    ),
                  ),
                );
              }

              final conversation = snapshot.data!;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                    child: AppPanel(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            color: AppColors.blue,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Read-only shared chat',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        conversation.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      itemCount: conversation.messages.length,
                      itemBuilder: (context, index) => ChatMessageBubble(
                        message: conversation.messages[index],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
