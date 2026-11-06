import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/notes_provider.dart';
import '../services/ai_chat_service.dart';
import '../services/chat_history_service.dart';
import '../services/note_reminder_service.dart';
import '../services/notes_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'notes_home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.reminderService});

  final NoteReminderService reminderService;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return switch (auth.status) {
          AuthStatus.loading => const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            ),
          ),
          AuthStatus.signedOut => const AuthScreen(),
          AuthStatus.signedIn => _AuthenticatedApp(
            user: auth.user!,
            reminderService: reminderService,
          ),
          AuthStatus.error => Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  auth.errorMessage ?? 'Something went wrong.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        };
      },
    );
  }
}

class _AuthenticatedApp extends StatelessWidget {
  const _AuthenticatedApp({
    required this.user,
    required this.reminderService,
  });

  final User user;
  final NoteReminderService reminderService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => NotesProvider(
            FirestoreNotesService(userId: user.uid),
            userId: user.uid,
            reminderService: reminderService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            const FirebaseAiChatService(),
            FirestoreChatHistoryService(userId: user.uid),
          ),
        ),
      ],
      child: NotesHomeScreen(user: user, reminderService: reminderService),
    );
  }
}
