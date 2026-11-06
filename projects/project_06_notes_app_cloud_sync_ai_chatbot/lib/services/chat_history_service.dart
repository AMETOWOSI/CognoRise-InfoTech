import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/shared_chat.dart';
import 'chat_share_links.dart';

abstract interface class ChatHistoryService {
  Stream<List<ChatConversation>> watchConversations();

  Future<String> createConversation();

  Future<List<ChatMessage>> loadMessages(String conversationId);

  Future<void> saveMessage(String conversationId, ChatMessage message);

  Future<void> deleteConversation(String conversationId);

  Future<Uri> createShareLink(String conversationId);

  Future<void> revokeShareLink(String conversationId);
}

class FirestoreChatHistoryService implements ChatHistoryService {
  FirestoreChatHistoryService({
    required String userId,
    FirebaseFirestore? firestore,
  }) : _userId = userId,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final String _userId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('users').doc(_userId).collection('chats');

  @override
  Stream<List<ChatConversation>> watchConversations() {
    return _conversations
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => _conversationFromDocument(document))
              .toList(growable: false),
        );
  }

  @override
  Future<String> createConversation() async {
    final document = _conversations.doc();
    final now = FieldValue.serverTimestamp();
    await document.set({
      'title': 'New chat',
      'createdAt': now,
      'updatedAt': now,
    });
    return document.id;
  }

  @override
  Future<List<ChatMessage>> loadMessages(String conversationId) async {
    final snapshot = await _messages(conversationId).orderBy('createdAt').get();
    return snapshot.docs
        .map((document) => _messageFromData(document.data()))
        .toList(growable: false);
  }

  @override
  Future<void> saveMessage(String conversationId, ChatMessage message) async {
    final text = message.text.trim();
    if (text.isEmpty || text.length > 20000) {
      throw ArgumentError.value(
        message.text.length,
        'message.text.length',
        'Messages must contain between 1 and 20000 characters.',
      );
    }

    final conversation = _conversations.doc(conversationId);
    final snapshot = await conversation.get();
    if (!snapshot.exists) {
      throw StateError('The selected conversation no longer exists.');
    }

    final updates = <String, Object?>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final currentTitle = snapshot.data()?['title'];
    if (message.role == ChatMessageRole.user &&
        (currentTitle == null || currentTitle == 'New chat')) {
      updates['title'] = _titleFromMessage(text);
    }

    final batch = _firestore.batch()
      ..set(_messages(conversationId).doc(), {
        'role': _roleName(message.role),
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..update(conversation, updates);
    await batch.commit();
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    final conversation = _conversations.doc(conversationId);
    final snapshot = await conversation.get();
    if (!snapshot.exists) return;
    final shareId = snapshot.data()?['shareId'];
    if (shareId is String && shareId.isNotEmpty) {
      await _deleteSharedChat(shareId);
    }

    await _deleteCollectionInBatches(_messages(conversationId));
    await conversation.delete();
  }

  @override
  Future<Uri> createShareLink(String conversationId) async {
    final conversation = _conversations.doc(conversationId);
    final snapshot = await conversation.get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('The selected conversation no longer exists.');
    }

    final currentShareId = data['shareId'];
    if (currentShareId is String && currentShareId.isNotEmpty) {
      final existingShare = await _firestore
          .collection('sharedChats')
          .doc(currentShareId)
          .get();
      if (existingShare.exists) return _shareUri(currentShareId);
    }

    final messages = await _messages(conversationId).orderBy('createdAt').get();
    if (messages.docs.isEmpty) {
      throw StateError('Send a message before sharing this conversation.');
    }

    final share = _firestore.collection('sharedChats').doc();
    final shareId = share.id;
    try {
      await share.set({
        'ownerUid': _userId,
        'title': _shareTitle(data['title']),
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (var start = 0; start < messages.docs.length; start += 450) {
        final batch = _firestore.batch();
        final end = messages.docs.length < start + 450
            ? messages.docs.length
            : start + 450;
        for (final message in messages.docs.sublist(start, end)) {
          final messageData = message.data();
          batch.set(share.collection('messages').doc(), {
            'role': messageData['role'],
            'text': messageData['text'],
            'createdAt': messageData['createdAt'],
          });
        }
        await batch.commit();
      }

      await conversation.update({
        'shareId': shareId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error, stackTrace) {
      await _deleteSharedChat(shareId);
      Error.throwWithStackTrace(error, stackTrace);
    }

    return _shareUri(shareId);
  }

  @override
  Future<void> revokeShareLink(String conversationId) async {
    final conversation = _conversations.doc(conversationId);
    final snapshot = await conversation.get();
    final shareId = snapshot.data()?['shareId'];
    if (shareId is! String || shareId.isEmpty) return;

    await _deleteSharedChat(shareId);
    await conversation.update({
      'shareId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  CollectionReference<Map<String, dynamic>> _messages(String conversationId) =>
      _conversations.doc(conversationId).collection('messages');

  ChatConversation _conversationFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return ChatConversation(
      id: document.id,
      title: _stringValue(data['title'], fallback: 'New chat'),
      createdAt: _dateValue(data['createdAt']),
      updatedAt: _dateValue(data['updatedAt']),
      shareId: data['shareId'] is String ? data['shareId'] as String : null,
    );
  }

  ChatMessage _messageFromData(Map<String, dynamic> data) {
    final role = data['role'];
    final text = data['text'];
    if (role is! String || text is! String || text.trim().isEmpty) {
      throw const FormatException('A chat message is invalid.');
    }
    return ChatMessage(
      text: text,
      role: switch (role) {
        'user' => ChatMessageRole.user,
        'assistant' => ChatMessageRole.assistant,
        _ => throw const FormatException('A chat message role is invalid.'),
      },
      createdAt: _dateValue(data['createdAt']),
    );
  }

  String _roleName(ChatMessageRole role) => switch (role) {
    ChatMessageRole.user => 'user',
    ChatMessageRole.assistant => 'assistant',
  };

  DateTime _dateValue(Object? value) {
    return switch (value) {
      Timestamp timestamp => timestamp.toDate(),
      DateTime dateTime => dateTime,
      _ => throw const FormatException('A chat timestamp is invalid.'),
    };
  }

  String _stringValue(Object? value, {required String fallback}) =>
      value is String && value.isNotEmpty ? value : fallback;

  String _titleFromMessage(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.length <= 60
        ? normalized
        : '${normalized.substring(0, 57)}...';
  }

  String _shareTitle(Object? title) {
    if (title is! String || title.trim().isEmpty) return 'Shared conversation';
    return title.length <= 80 ? title : title.substring(0, 77);
  }

  Uri _shareUri(String shareId) => ChatShareLinks.forId(shareId);

  Future<void> _deleteSharedChat(String shareId) async {
    final share = _firestore.collection('sharedChats').doc(shareId);
    final snapshot = await share.get();
    if (!snapshot.exists) return;
    if (snapshot.data()?['revoked'] != true) {
      await share.update({'revoked': true});
    }
    await _deleteCollectionInBatches(share.collection('messages'));
    await share.delete();
  }

  Future<void> _deleteCollectionInBatches(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(450).get();
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }
}

abstract interface class SharedChatReader {
  Future<SharedChat> loadSharedChat(String shareId);
}

class FirestoreSharedChatReader implements SharedChatReader {
  FirestoreSharedChatReader({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<SharedChat> loadSharedChat(String shareId) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{20}$').hasMatch(shareId)) {
      throw const SharedChatNotFoundException();
    }

    final share = _firestore.collection('sharedChats').doc(shareId);
    final snapshot = await share.get();
    final data = snapshot.data();
    if (data == null) throw const SharedChatNotFoundException();

    final title = data['title'];
    if (title is! String || title.isEmpty) {
      throw const FormatException('The shared conversation is invalid.');
    }

    final messageSnapshot = await share
        .collection('messages')
        .orderBy('createdAt')
        .get();
    return SharedChat(
      title: title,
      messages: messageSnapshot.docs
          .map((document) => _sharedMessageFromData(document.data()))
          .toList(growable: false),
    );
  }
}

ChatMessage _sharedMessageFromData(Map<String, dynamic> data) {
  final role = data['role'];
  final text = data['text'];
  final createdAt = data['createdAt'];
  if (role is! String ||
      text is! String ||
      text.trim().isEmpty ||
      createdAt is! Timestamp) {
    throw const FormatException('A shared chat message is invalid.');
  }
  return ChatMessage(
    text: text,
    role: switch (role) {
      'user' => ChatMessageRole.user,
      'assistant' => ChatMessageRole.assistant,
      _ => throw const FormatException(
        'A shared chat message role is invalid.',
      ),
    },
    createdAt: createdAt.toDate(),
  );
}

class SharedChatNotFoundException implements Exception {
  const SharedChatNotFoundException();
}
