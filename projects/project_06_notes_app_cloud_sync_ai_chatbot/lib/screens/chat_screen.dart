import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/chat_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.onAccountTap,
    required this.onNotificationsTap,
  });

  final VoidCallback onAccountTap;
  final VoidCallback onNotificationsTap;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    final sent = await context.read<ChatProvider>().sendMessage(message);
    if (sent && mounted) _messageController.clear();
  }

  Future<void> _startNewConversation() async {
    final provider = context.read<ChatProvider>();
    if (provider.messages.isEmpty || provider.isSending) return;

    final shouldStart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new chat?'),
        content: const Text(
          'This conversation will remain in your chat history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('New chat'),
          ),
        ],
      ),
    );
    if (shouldStart == true && mounted) {
      provider.startNewConversation();
    }
  }

  Future<void> _deleteConversation(ChatConversation conversation) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this chat?'),
        content: const Text(
          'This permanently deletes the conversation and revokes its share link.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete chat'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    try {
      await context.read<ChatProvider>().deleteConversation(conversation.id);
      if (mounted) _showMessage('Chat deleted.');
    } on Exception catch (error, stackTrace) {
      debugPrint('Could not delete chat: $error\n$stackTrace');
      if (mounted) _showMessage('Could not delete this chat. Try again.');
    }
  }

  Future<void> _shareConversation(ChatConversation conversation) async {
    final shouldShare = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          conversation.shareId == null
              ? 'Create a share link?'
              : 'Share existing snapshot?',
        ),
        content: Text(
          conversation.shareId == null
              ? 'Anyone who gets the link can read a read-only snapshot of this '
                    'conversation. Messages added later are not included. You '
                    'can revoke the link from your chat list.'
              : 'Anyone who gets this link can read its read-only snapshot. '
                    'Messages added since it was first shared are not included. '
                    'Revoke the existing link before sharing again to create a '
                    'new snapshot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              conversation.shareId == null ? 'Create link' : 'Share link',
            ),
          ),
        ],
      ),
    );
    if (shouldShare != true || !mounted) return;

    try {
      final link = await context.read<ChatProvider>().createShareLink(
        conversation.id,
      );
      await SharePlus.instance.share(ShareParams(uri: link));
    } on Exception catch (error, stackTrace) {
      debugPrint('Could not share chat: $error\n$stackTrace');
      if (mounted) {
        _showMessage(
          'Could not create or share this link. Check your connection and '
          'Firestore rules.',
        );
      }
    }
  }

  Future<void> _revokeShareLink(ChatConversation conversation) async {
    final shouldRevoke = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke share link?'),
        content: const Text(
          'People with the link will no longer be able to open this shared '
          'copy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep link'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke link'),
          ),
        ],
      ),
    );
    if (shouldRevoke != true || !mounted) return;
    try {
      await context.read<ChatProvider>().revokeShareLink(conversation.id);
      if (mounted) _showMessage('Share link revoked.');
    } on Exception catch (error, stackTrace) {
      debugPrint('Could not revoke chat share link: $error\n$stackTrace');
      if (mounted) _showMessage('Could not revoke the share link.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _handleConversationAction(String action, ChatConversation conversation) {
    switch (action) {
      case 'share':
        unawaited(_shareConversation(conversation));
        return;
      case 'revoke':
        unawaited(_revokeShareLink(conversation));
        return;
      case 'delete':
        unawaited(_deleteConversation(conversation));
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _ChatHistoryDrawer(
        onNewChat: _startNewConversation,
        onMenuAction: _handleConversationAction,
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              children: [
                _ChatHeader(
                  onNewChat: _startNewConversation,
                  onAccountTap: widget.onAccountTap,
                  onNotificationsTap: widget.onNotificationsTap,
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Consumer<ChatProvider>(
                    builder: (context, provider, _) {
                      return Column(
                        children: [
                          if (provider.errorMessage != null)
                            _ChatErrorBanner(
                              message: provider.errorMessage!,
                              onDismiss: provider.dismissError,
                            ),
                          Expanded(
                            child: provider.isLoadingConversation
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.blue,
                                    ),
                                  )
                                : provider.messages.isEmpty
                                ? const _ChatWelcome()
                                : _MessageList(
                                    messages: provider.messages,
                                    isSending: provider.isSending,
                                  ),
                          ),
                          const SizedBox(height: 12),
                          _MessageComposer(
                            controller: _messageController,
                            isSending: provider.isSending,
                            onSend: _sendMessage,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.onNewChat,
    required this.onAccountTap,
    required this.onNotificationsTap,
  });

  final VoidCallback onNewChat;
  final VoidCallback onAccountTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: const Key('chatHistoryButton'),
          tooltip: 'Chat history',
          onPressed: () => Scaffold.of(context).openDrawer(),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.blue.withValues(alpha: 0.12),
            fixedSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.menu, color: AppColors.blue, size: 27),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NoteFlow AI',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'Ask, brainstorm, and get organized',
                style: TextStyle(color: AppColors.mutedInk, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          key: const Key('newChatButton'),
          tooltip: 'New chat',
          onPressed: onNewChat,
          icon: const Icon(Icons.add_comment_outlined),
          color: AppColors.mutedInk,
        ),
        IconButton(
          key: const Key('accountInfoButton'),
          tooltip: 'Account information',
          onPressed: onAccountTap,
          icon: const Icon(Icons.account_circle_outlined),
          color: AppColors.blue,
        ),
        IconButton(
          key: const Key('notificationsButton'),
          tooltip: 'Notifications',
          onPressed: onNotificationsTap,
          icon: const Icon(Icons.notifications_none_outlined),
          color: AppColors.blue,
        ),
      ],
    );
  }
}

class _ChatHistoryDrawer extends StatelessWidget {
  const _ChatHistoryDrawer({
    required this.onNewChat,
    required this.onMenuAction,
  });

  final VoidCallback onNewChat;
  final void Function(String action, ChatConversation conversation)
  onMenuAction;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: Text(
                'Your conversations',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              trailing: IconButton(
                key: const Key('drawerNewChatButton'),
                tooltip: 'New chat',
                onPressed: () {
                  Navigator.pop(context);
                  onNewChat();
                },
                icon: const Icon(Icons.add_comment_outlined),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, _) {
                  if (provider.conversations.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Your conversations will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.mutedInk),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: provider.conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = provider.conversations[index];
                      return ListTile(
                        key: ValueKey('chat-${conversation.id}'),
                        selected:
                            provider.activeConversationId == conversation.id,
                        leading: const Icon(Icons.chat_bubble_outline),
                        title: Text(
                          conversation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Chat actions',
                          onSelected: (action) =>
                              onMenuAction(action, conversation),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'share',
                              child: Text('Share link'),
                            ),
                            if (conversation.shareId != null)
                              const PopupMenuItem(
                                value: 'revoke',
                                child: Text('Revoke share link'),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete chat'),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.read<ChatProvider>().selectConversation(
                            conversation.id,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatWelcome extends StatelessWidget {
  const _ChatWelcome();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 220;
        return Center(
          child: AppPanel(
            padding: EdgeInsets.all(compact ? 14 : 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: compact ? 48 : 64,
                  width: compact ? 48 : 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.blue, AppColors.deepBlue],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: compact ? 26 : 32,
                  ),
                ),
                SizedBox(height: compact ? 10 : 18),
                Text(
                  'What would you like to work on?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 7),
                  const Text(
                    'Ask for ideas, summaries, or help turning a thought into '
                    'a plan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.mutedInk, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages, required this.isSending});

  final List<ChatMessage> messages;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final itemCount = messages.length + (isSending ? 1 : 0);

    return ListView.builder(
      key: const Key('chatMessagesList'),
      reverse: true,
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (isSending && index == 0) return const _TypingIndicator();
        final messageIndex = messages.length - 1 - index + (isSending ? 1 : 0);
        if (messageIndex < 0 || messageIndex >= messages.length) {
          return const SizedBox.shrink();
        }
        return ChatMessageBubble(message: messages[messageIndex]);
      },
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: AppPanel(
          padding: EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          child: SizedBox(
            height: 18,
            width: 30,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatErrorBanner extends StatelessWidget {
  const _ChatErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                ),
              ),
              IconButton(
                tooltip: 'Dismiss error',
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const Key('chatMessageField'),
              controller: controller,
              enabled: !isSending,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: isSending ? null : (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Message your assistant…',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 46,
            width: 46,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.blue, AppColors.deepBlue],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              key: const Key('sendChatMessageButton'),
              tooltip: 'Send message',
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.arrow_upward, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
