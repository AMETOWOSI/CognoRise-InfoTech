import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/models/chat_conversation.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/models/chat_message.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/models/note.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/models/shared_chat.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/providers/auth_provider.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/providers/chat_provider.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/providers/notes_provider.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/screens/chat_screen.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/screens/notes_home_screen.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/screens/notes_screen.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/screens/shared_chat_screen.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/services/auth_service.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/services/ai_chat_service.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/services/chat_history_service.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/services/chat_share_links.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/services/note_reminder_service.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/services/notes_service.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows the saved profile photo in the notes header', (
    tester,
  ) async {
    final service = _FakeNotesService();
    addTearDown(service.dispose);
    await tester.pumpWidget(
      _notesApp(service, userPhotoUrl: 'https://example.com/avatar.jpg'),
    );

    final image = tester.widget<Image>(
      find.byKey(const Key('homeProfilePhotoImage')),
    );
    expect((image.image as NetworkImage).url, 'https://example.com/avatar.jpg');
    expect(find.byKey(const Key('homeProfilePhoto')), findsOneWidget);
  });

  testWidgets('creates and edits a note', (tester) async {
    final service = _FakeNotesService();
    addTearDown(service.dispose);
    await tester.pumpWidget(_notesApp(service));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('createNoteButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('noteTitleField')),
      'First idea',
    );
    await tester.enterText(
      find.byKey(const Key('noteContentField')),
      'Remember this detail',
    );
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();

    expect(find.text('First idea'), findsOneWidget);
    expect(find.text('Remember this detail'), findsOneWidget);

    await tester.tap(find.text('First idea'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('noteTitleField')),
      'Updated idea',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Updated idea'), findsOneWidget);
    expect(find.text('First idea'), findsNothing);

    await tester.tap(find.byTooltip('Note actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Your notes start here'), findsOneWidget);
  });

  testWidgets('schedules a device-local reminder for a note', (tester) async {
    final service = _FakeNotesService();
    final reminders = _FakeNoteReminderService();
    addTearDown(service.dispose);
    await tester.pumpWidget(_notesApp(service, reminderService: reminders));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('createNoteButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('noteTitleField')),
      'Reminder test',
    );
    await tester.tap(find.byKey(const Key('setNoteReminderButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Reminder set'), findsOneWidget);
    await tester.ensureVisible(find.text('Save note'));
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();

    expect(reminders.reminders, contains('test-user/0'));

    await tester.tap(find.text('Reminder test'));
    await tester.pumpAndSettle();
    expect(find.text('Reminder set'), findsOneWidget);
    await tester.tap(find.byKey(const Key('clearNoteReminderButton')));
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(reminders.reminders, isEmpty);
  });

  testWidgets('sends a message and shows the assistant reply', (tester) async {
    await tester.pumpWidget(_chatApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('chatMessageField')),
      'Help me plan my day',
    );
    await tester.tap(find.byKey(const Key('sendChatMessageButton')));
    await tester.pumpAndSettle();

    expect(find.text('Help me plan my day'), findsOneWidget);
    expect(find.text('Here is a simple plan.'), findsOneWidget);
  });

  testWidgets('lists chats and asks for confirmation before deleting', (
    tester,
  ) async {
    final history = _FakeChatHistoryService();
    await tester.pumpWidget(_chatApp(history: history));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('chatMessageField')),
      'A saved conversation',
    );
    await tester.tap(find.byKey(const Key('sendChatMessageButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chatHistoryButton')));
    await tester.pumpAndSettle();
    expect(find.text('A saved conversation'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Chat actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete chat'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this chat?'), findsOneWidget);
    await tester.tap(find.text('Delete chat').last);
    await tester.pumpAndSettle();

    expect(find.text('A saved conversation'), findsNothing);
  });

  testWidgets('warns that chat share links are public before creating one', (
    tester,
  ) async {
    await tester.pumpWidget(_chatApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('chatMessageField')),
      'Shareable conversation',
    );
    await tester.tap(find.byKey(const Key('sendChatMessageButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chatHistoryButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Chat actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share link'));
    await tester.pumpAndSettle();

    expect(find.text('Create a share link?'), findsOneWidget);
    expect(
      find.textContaining(
        'Anyone who gets the link can read a read-only snapshot',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('shows a shared chat as read-only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SharedChatScreen(
          shareId: '0123456789abcdefghij',
          reader: _FakeSharedChatReader(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Read-only shared chat'), findsOneWidget);
    expect(find.text('Shared test conversation'), findsOneWidget);
    expect(find.text('This is a shared message.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  test('accepts only supported, well-formed share links', () {
    const shareId = '0123456789abcdefghij';
    expect(
      ChatShareLinks.shareIdFromUri(
        Uri.https(ChatShareLinks.host, '/share/$shareId'),
      ),
      shareId,
    );
    expect(
      ChatShareLinks.shareIdFromUri(Uri.parse('noteflow://share/$shareId')),
      shareId,
    );
    expect(
      ChatShareLinks.shareIdFromUri(
        Uri.https('attacker.example', '/share/$shareId'),
      ),
      isNull,
    );
    expect(
      ChatShareLinks.shareIdFromUri(
        Uri.https(ChatShareLinks.host, '/share/short'),
      ),
      isNull,
    );
  });

  testWidgets('hides bottom navigation and avoids overflow with keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final notesService = _FakeNotesService();
    addTearDown(notesService.dispose);

    await tester.pumpWidget(_homeApp(notesService));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI chat'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('chatMessageField')),
      'Testing keyboard layout',
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    final layoutError = tester.takeException();
    expect(layoutError, isNull);
  });

  testWidgets('shows Firestore reason when saving a note is denied', (
    tester,
  ) async {
    final service = _FakeNotesService(
      createError: FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      ),
    );
    addTearDown(service.dispose);
    await tester.pumpWidget(_notesApp(service));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('createNoteButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('noteTitleField')),
      'A note to save',
    );
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('noteSaveError')), findsOneWidget);
    expect(find.textContaining('permission-denied'), findsOneWidget);
    expect(find.text('New note'), findsNWidgets(2));
  });

  testWidgets('explains Firebase App Check attestation rejection', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ChatProvider(
          _FailingAiChatService(
            FirebaseException(
              plugin: 'firebase_ai',
              code: 'unknown',
              message:
                  'Error returned from API. code: 403 body: App attestation failed.',
            ),
          ),
          _FakeChatHistoryService(),
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          home: ChatScreen(onAccountTap: _noop, onNotificationsTap: _noop),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('chatMessageField')),
      'Test app check',
    );
    await tester.tap(find.byKey(const Key('sendChatMessageButton')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Firebase AI Logic denied this request'),
      findsOneWidget,
    );
    expect(find.textContaining('debug token'), findsOneWidget);
  });

  testWidgets(
    'explains Firestore permission denial when creating chat history',
    (tester) async {
      final history = _FakeChatHistoryService(
        createError: FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Missing or insufficient permissions.',
        ),
      );
      await tester.pumpWidget(_chatApp(history: history));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('chatMessageField')),
        'Check my chat setup',
      );
      await tester.tap(find.byKey(const Key('sendChatMessageButton')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Firestore denied this chat-history request'),
        findsOneWidget,
      );
      expect(find.textContaining('firestore.rules'), findsOneWidget);
    },
  );
}

Widget _notesApp(
  NotesService service, {
  _FakeNoteReminderService? reminderService,
  String? userPhotoUrl,
}) {
  final reminders = reminderService ?? _FakeNoteReminderService();
  return MaterialApp(
    theme: AppTheme.light,
    home: ChangeNotifierProvider(
      create: (_) => NotesProvider(
        service,
        userId: 'test-user',
        reminderService: reminders,
      ),
      child: NotesScreen(
        userName: 'Notes User',
        userEmail: 'notes@example.com',
        userPhotoUrl: userPhotoUrl,
        userId: 'test-user',
        reminderService: reminders,
        onAccountTap: _noop,
        onNotificationsTap: _noop,
      ),
    ),
  );
}

Widget _chatApp({_FakeChatHistoryService? history}) {
  return ChangeNotifierProvider(
    create: (_) => ChatProvider(
      const _FakeAiChatService(),
      history ?? _FakeChatHistoryService(),
    ),
    child: MaterialApp(
      theme: AppTheme.light,
      home: ChatScreen(onAccountTap: _noop, onNotificationsTap: _noop),
    ),
  );
}

Widget _homeApp(_FakeNotesService notesService) {
  final user = _TestUser();
  final reminders = _FakeNoteReminderService();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(_FakeAuthService(user)),
      ),
      ChangeNotifierProvider<NotesProvider>(
        create: (_) => NotesProvider(
          notesService,
          userId: user.uid,
          reminderService: reminders,
        ),
      ),
      ChangeNotifierProvider<ChatProvider>(
        create: (_) =>
            ChatProvider(const _FakeAiChatService(), _FakeChatHistoryService()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: NotesHomeScreen(user: user, reminderService: reminders),
    ),
  );
}

void _noop() {}

class _FakeNoteReminderService implements NoteReminderService {
  final Map<String, DateTime> reminders = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<DateTime?> loadReminderAt(String userId, String noteId) async =>
      reminders['$userId/$noteId'];

  @override
  Future<void> scheduleReminder({
    required String userId,
    required String noteId,
    required DateTime? reminderAt,
  }) async {
    final key = '$userId/$noteId';
    if (reminderAt == null) {
      reminders.remove(key);
    } else {
      reminders[key] = reminderAt;
    }
  }

  @override
  Future<void> reconcileNotes(String userId, Set<String> noteIds) async {
    reminders.removeWhere((key, _) {
      final separator = key.indexOf('/');
      return key.substring(0, separator) == userId &&
          !noteIds.contains(key.substring(separator + 1));
    });
  }
}

class _FakeNotesService implements NotesService {
  _FakeNotesService({this.createError});

  final _controller = StreamController<List<Note>>.broadcast(sync: true);
  final List<Note> _notes = [];
  final Object? createError;
  int _nextId = 0;

  @override
  Stream<List<Note>> watchNotes() async* {
    yield List.unmodifiable(_notes);
    yield* _controller.stream;
  }

  @override
  Future<String> createNote({
    required String title,
    required String content,
  }) async {
    if (createError case final error?) throw error;
    final now = DateTime.now();
    final id = '${_nextId++}';
    _notes.add(
      Note(
        id: id,
        title: title.trim(),
        content: content.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
    _emit();
    return id;
  }

  @override
  Future<void> updateNote({
    required String id,
    required String title,
    required String content,
  }) async {
    final index = _notes.indexWhere((note) => note.id == id);
    final previous = _notes[index];
    _notes[index] = Note(
      id: id,
      title: title.trim(),
      content: content.trim(),
      createdAt: previous.createdAt,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  @override
  Future<void> deleteNote(String id) async {
    _notes.removeWhere((note) => note.id == id);
    _emit();
  }

  void _emit() => _controller.add(List.unmodifiable(_notes));

  Future<void> dispose() => _controller.close();
}

class _FakeAiChatService implements AiChatService {
  const _FakeAiChatService();

  @override
  AiChatConversation createConversation({
    List<ChatMessage> history = const [],
  }) => _FakeAiChatConversation();
}

class _FailingAiChatService implements AiChatService {
  const _FailingAiChatService(this.error);

  final Object error;

  @override
  AiChatConversation createConversation({
    List<ChatMessage> history = const [],
  }) => _FailingAiChatConversation(error);
}

class _FakeChatHistoryService implements ChatHistoryService {
  _FakeChatHistoryService({this.createError});

  final _controller = StreamController<List<ChatConversation>>.broadcast(
    sync: true,
  );
  final Map<String, List<ChatMessage>> _messages = {};
  final List<ChatConversation> _conversations = [];
  final Object? createError;
  int _nextId = 0;

  @override
  Stream<List<ChatConversation>> watchConversations() async* {
    yield List.unmodifiable(_conversations);
    yield* _controller.stream;
  }

  @override
  Future<String> createConversation() async {
    if (createError case final error?) throw error;
    final id = 'conversation-${_nextId++}';
    final now = DateTime.now();
    _conversations.insert(
      0,
      ChatConversation(
        id: id,
        title: 'New chat',
        createdAt: now,
        updatedAt: now,
      ),
    );
    _messages[id] = [];
    _emit();
    return id;
  }

  @override
  Future<List<ChatMessage>> loadMessages(String conversationId) async =>
      List.unmodifiable(_messages[conversationId] ?? []);

  @override
  Future<void> saveMessage(String conversationId, ChatMessage message) async {
    final messages = _messages[conversationId]!;
    messages.add(message);
    final index = _conversations.indexWhere(
      (conversation) => conversation.id == conversationId,
    );
    if (index >= 0) {
      final previous = _conversations.removeAt(index);
      _conversations.insert(
        0,
        ChatConversation(
          id: conversationId,
          title:
              previous.title == 'New chat' &&
                  message.role == ChatMessageRole.user
              ? message.text
              : previous.title,
          createdAt: previous.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
      _emit();
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((item) => item.id == conversationId);
    _messages.remove(conversationId);
    _emit();
  }

  @override
  Future<Uri> createShareLink(String conversationId) async =>
      Uri.https('notes-cloud-a9ea8.web.app', '/share/$conversationId');

  @override
  Future<void> revokeShareLink(String conversationId) async {}

  void _emit() => _controller.add(List.unmodifiable(_conversations));
}

class _FakeSharedChatReader implements SharedChatReader {
  @override
  Future<SharedChat> loadSharedChat(String shareId) async => SharedChat(
    title: 'Shared test conversation',
    messages: [
      ChatMessage(
        text: 'This is a shared message.',
        role: ChatMessageRole.user,
        createdAt: DateTime(2026),
      ),
    ],
  );
}

class _FakeAuthService implements AuthService {
  _FakeAuthService(this._user);

  final User _user;

  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(_user);

  @override
  User? get currentUser => _user;

  @override
  Future<void> createAccount({
    required String displayName,
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updateDisplayName(String displayName) async {}

  @override
  Future<void> updateEmail({
    required String email,
    required String currentPassword,
  }) async {}

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async {}
}

class _TestUser implements User {
  @override
  final String uid = 'test-user';

  @override
  final String? email = 'test@example.com';

  @override
  final String? displayName = 'Test User';

  @override
  final String? photoURL = null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingAiChatConversation implements AiChatConversation {
  const _FailingAiChatConversation(this.error);

  final Object error;

  @override
  Future<String> sendMessage(String message) async => throw error;
}

class _FakeAiChatConversation implements AiChatConversation {
  @override
  Future<String> sendMessage(String message) async => 'Here is a simple plan.';
}
