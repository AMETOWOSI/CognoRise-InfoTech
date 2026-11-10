import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/providers/auth_provider.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/screens/account_info_screen.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/services/auth_service.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/services/profile_photo_service.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('saves account display name', (tester) async {
    final service = _AccountTestAuthService();
    await tester.pumpWidget(
      _accountApp(service, photoService: _AccountTestPhotoService()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('accountDisplayNameField')),
      'New display name',
    );
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(service.displayName, 'New display name');
    expect(find.text('Your profile has been updated.'), findsOneWidget);
  });

  testWidgets('saves and shows the local account profile photo', (
    tester,
  ) async {
    final photoService = _AccountTestPhotoService();
    final authService = _AccountTestAuthService();
    await tester.pumpWidget(
      _accountApp(authService, photoService: photoService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addProfilePhotoButton')));
    await tester.pumpAndSettle();

    expect(photoService.didPick, isTrue);
    expect(
      find.text('Your profile photo is saved on this device.'),
      findsOneWidget,
    );
    final image = tester.widget<Image>(find.byType(Image).first);
    expect(image.image, isA<FileImage>());
    expect((image.image as FileImage).file.path, '/local/avatar');
  });
}

Widget _accountApp(
  AuthService service, {
  required ProfilePhotoService photoService,
}) {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(service),
    child: MaterialApp(
      theme: AppTheme.light,
      home: AccountInfoScreen(
        onSignOut: () async {},
        profilePhotoService: photoService,
      ),
    ),
  );
}

class _AccountTestAuthService implements AuthService {
  _AccountTestAuthService()
    : _user = _AccountTestUser(displayName: 'Test User');

  final _AccountTestUser _user;

  String? get displayName => _user.displayName;

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
  Future<void> updateDisplayName(String displayName) async {
    _user.displayName = displayName;
  }

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

class _AccountTestPhotoService implements ProfilePhotoService {
  bool didPick = false;

  @override
  Future<String?> loadLocalPhoto(String userId) async => null;

  @override
  Future<String?> pickAndSave(String userId) async {
    didPick = true;
    return '/local/avatar';
  }

  @override
  Future<void> delete(String userId) async {}
}

class _AccountTestUser implements User {
  _AccountTestUser({required this.displayName});

  @override
  final String uid = 'test-user';

  @override
  final String? email = 'test@example.com';

  @override
  String? displayName;

  @override
  String? photoURL;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
