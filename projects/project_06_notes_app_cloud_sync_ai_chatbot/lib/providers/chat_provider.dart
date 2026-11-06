import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../services/ai_chat_service.dart';
import '../services/chat_history_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider(this._service, this._historyService)
    : _conversation = _service.createConversation() {
    _historySubscription = _historyService.watchConversations().listen(
      (conversations) {
        _conversations = conversations;
        _notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _reportError(error, stackTrace);
        _errorMessage = 'Could not load chat history. Check your connection.';
        _notifyListeners();
      },
    );
  }

  static const maxPromptLength = 10000;

  final AiChatService _service;
  final ChatHistoryService _historyService;
  late final StreamSubscription<List<ChatConversation>> _historySubscription;
  AiChatConversation _conversation;
  List<ChatConversation> _conversations = [];
  final List<ChatMessage> _messages = [];
  String? _activeConversationId;
  bool _isSending = false;
  bool _isLoadingConversation = false;
  bool _isDisposed = false;
  String? _errorMessage;

  List<ChatConversation> get conversations => List.unmodifiable(_conversations);
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  bool get isLoadingConversation => _isLoadingConversation;
  String? get errorMessage => _errorMessage;
  String? get activeConversationId => _activeConversationId;
  ChatConversation? get activeConversation {
    final id = _activeConversationId;
    if (id == null) return null;
    for (final conversation in _conversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  Future<bool> sendMessage(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty || _isSending) return false;
    if (message.length > maxPromptLength) {
      _errorMessage = 'Messages can contain up to $maxPromptLength characters.';
      _notifyListeners();
      return false;
    }

    _isSending = true;
    _errorMessage = null;
    _notifyListeners();

    try {
      _activeConversationId ??= await _historyService.createConversation();
      final conversationId = _activeConversationId!;
      final userMessage = ChatMessage(
        text: message,
        role: ChatMessageRole.user,
        createdAt: DateTime.now(),
      );

      try {
        await _historyService.saveMessage(conversationId, userMessage);
      } on FirebaseException catch (error, stackTrace) {
        _reportError(error, stackTrace);
        _errorMessage = _firebaseErrorMessage(error, savingHistory: true);
        return false;
      } on Exception catch (error, stackTrace) {
        _reportError(error, stackTrace);
        _errorMessage = 'Could not save your message. Please try again.';
        return false;
      }

      _messages.add(userMessage);
      _notifyListeners();

      final response = await _conversation.sendMessage(message);
      final assistantMessage = ChatMessage(
        text: response,
        role: ChatMessageRole.assistant,
        createdAt: DateTime.now(),
      );
      _messages.add(assistantMessage);
      _notifyListeners();

      try {
        await _historyService.saveMessage(conversationId, assistantMessage);
      } on FirebaseException catch (error, stackTrace) {
        _reportError(error, stackTrace);
        _errorMessage =
            'The response was generated, but could not be saved to chat '
            'history. Check your connection.';
      } on Exception catch (error, stackTrace) {
        _reportError(error, stackTrace);
        _errorMessage =
            'The response was generated, but could not be saved to chat '
            'history.';
      }
      return true;
    } on FirebaseAIException catch (error, stackTrace) {
      _reportError(error, stackTrace);
      _errorMessage = _isPermissionDenied('unknown', error.message)
          ? _aiAccessError
          : 'The AI assistant is unavailable. Check your Firebase AI Logic '
                'configuration and try again.\nDetails: ${error.message}';
      return true;
    } on FirebaseException catch (error, stackTrace) {
      _reportError(error, stackTrace);
      _errorMessage = _firebaseErrorMessage(error);
      return false;
    } on EmptyAiResponseException catch (error, stackTrace) {
      _reportError(error, stackTrace);
      _errorMessage =
          'The assistant returned an empty response. Try another question.';
      return true;
    } on Exception catch (error, stackTrace) {
      _reportError(error, stackTrace);
      _errorMessage = 'Something went wrong. Please try again in a moment.';
      return true;
    } finally {
      _isSending = false;
      _notifyListeners();
    }
  }

  Future<void> selectConversation(String conversationId) async {
    if (_isSending || _activeConversationId == conversationId) return;
    _activeConversationId = conversationId;
    _messages.clear();
    _errorMessage = null;
    _isLoadingConversation = true;
    _conversation = _service.createConversation();
    _notifyListeners();

    try {
      final messages = await _historyService.loadMessages(conversationId);
      if (_isDisposed || _activeConversationId != conversationId) return;
      _messages
        ..clear()
        ..addAll(messages);
      _conversation = _service.createConversation(history: messages);
    } on FirebaseException catch (error, stackTrace) {
      _reportError(error, stackTrace);
      if (_activeConversationId == conversationId) {
        _errorMessage = _firebaseErrorMessage(error);
      }
    } on Exception catch (error, stackTrace) {
      _reportError(error, stackTrace);
      if (_activeConversationId == conversationId) {
        _errorMessage = 'Could not open this conversation. Please try again.';
      }
    } finally {
      if (!_isDisposed && _activeConversationId == conversationId) {
        _isLoadingConversation = false;
        _notifyListeners();
      }
    }
  }

  void startNewConversation() {
    if (_isSending) return;
    _activeConversationId = null;
    _messages.clear();
    _errorMessage = null;
    _conversation = _service.createConversation();
    _notifyListeners();
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _historyService.deleteConversation(conversationId);
      if (_activeConversationId == conversationId) {
        startNewConversation();
      }
    } on FirebaseException catch (error, stackTrace) {
      _reportError(error, stackTrace);
      _errorMessage = 'Could not delete this conversation. Please try again.';
      _notifyListeners();
      rethrow;
    } on Exception catch (error, stackTrace) {
      _reportError(error, stackTrace);
      _errorMessage = 'Could not delete this conversation. Please try again.';
      _notifyListeners();
      rethrow;
    }
  }

  Future<Uri> createShareLink(String conversationId) =>
      _historyService.createShareLink(conversationId);

  Future<void> revokeShareLink(String conversationId) async {
    try {
      await _historyService.revokeShareLink(conversationId);
    } on FirebaseException catch (error, stackTrace) {
      _reportError(error, stackTrace);
      _errorMessage = 'Could not revoke this share link. Please try again.';
      _notifyListeners();
      rethrow;
    }
  }

  void dismissError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _notifyListeners();
  }

  String _firebaseErrorMessage(
    FirebaseException error, {
    bool savingHistory = false,
  }) {
    final details = error.message ?? '';
    if (_isPermissionDenied(error.code, details)) {
      if (error.plugin == 'firebase_ai') return _aiAccessError;
      return savingHistory
          ? 'Firestore denied access to chat history. Deploy the current '
                'firestore.rules and confirm you are signed in to the expected '
                'Firebase project.'
          : 'Firestore denied this chat-history request. Confirm that the '
                'current firestore.rules are deployed and that you are signed '
                'in to the expected Firebase project.';
    }
    if (savingHistory) {
      return 'Could not save your conversation to Firestore. Check your '
          'connection and Firebase security rules.';
    }
    return 'Firebase request failed (${error.code}). $details';
  }

  bool _isPermissionDenied(String code, String message) {
    final normalizedMessage = message.toLowerCase();
    return code == 'permission-denied' ||
        normalizedMessage.contains('permission_denied') ||
        normalizedMessage.contains('permission-denied') ||
        normalizedMessage.contains('app attestation failed');
  }

  static const _aiAccessError =
      'Firebase AI Logic denied this request. In Firebase Console, confirm '
      'that Firebase AI Logic and the Gemini Developer API are enabled, then '
      'check Security > App Check > APIs for Firebase AI Logic. A debug build '
      'needs this device’s debug token registered; a release build needs Play '
      'Integrity configured for this Android app. This is separate from '
      'Firestore rules.';

  void _reportError(Object error, StackTrace stackTrace) {
    debugPrint('Chat operation failed: $error\n$stackTrace');
  }

  void _notifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _historySubscription.cancel();
    super.dispose();
  }
}
