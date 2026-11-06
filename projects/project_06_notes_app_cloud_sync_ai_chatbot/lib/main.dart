import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_gate.dart';
import 'screens/shared_chat_screen.dart';
import 'services/auth_service.dart';
import 'services/chat_history_service.dart';
import 'services/chat_share_links.dart';
import 'services/note_reminder_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
  );
  final reminderService = LocalNoteReminderService.instance;
  try {
    await reminderService.initialize();
  } on Exception catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'note reminders',
        context: ErrorDescription('while initializing local note reminders'),
      ),
    );
  }
  runApp(MyApp(reminderService: reminderService));
}

class MyApp extends StatefulWidget {
  MyApp({
    super.key,
    AuthService? authService,
    NoteReminderService? reminderService,
    this.enableDeepLinks = true,
  }) : _authService = authService ?? FirebaseAuthService(FirebaseAuth.instance),
       _reminderService =
           reminderService ?? LocalNoteReminderService.instance;

  final AuthService _authService;
  final NoteReminderService _reminderService;
  final bool enableDeepLinks;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _activeShareId;

  @override
  void initState() {
    super.initState();
    if (widget.enableDeepLinks) unawaited(_listenForAppLinks());
  }

  Future<void> _listenForAppLinks() async {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _openSharedChat,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Could not receive an app link: $error\n$stackTrace');
      },
    );
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) _openSharedChat(initialLink);
    } on Exception catch (error, stackTrace) {
      debugPrint('Could not read the initial app link: $error\n$stackTrace');
    }
  }

  void _openSharedChat(Uri link) {
    final shareId = ChatShareLinks.shareIdFromUri(link);
    if (shareId == null || shareId == _activeShareId) return;
    _activeShareId = shareId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      if (!mounted || navigator == null) {
        _activeShareId = null;
        return;
      }
      unawaited(
        navigator
            .push<void>(
              MaterialPageRoute<void>(
                settings: RouteSettings(name: '/share/$shareId'),
                builder: (_) => SharedChatScreen(
                  shareId: shareId,
                  reader: FirestoreSharedChatReader(),
                ),
              ),
            )
            .whenComplete(() {
              if (_activeShareId == shareId) _activeShareId = null;
            }),
      );
    });
  }

  @override
  void dispose() {
    unawaited(_linkSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(widget._authService),
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'NoteFlow',
        theme: AppTheme.light,
        home: AuthGate(reminderService: widget._reminderService),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
