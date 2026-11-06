import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/main.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/services/auth_service.dart';

class _TestAuthService implements AuthService {
  String? createdDisplayName;
  String? resetEmail;

  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(null);

  @override
  User? get currentUser => null;

  @override
  Future<void> createAccount({
    required String displayName,
    required String email,
    required String password,
  }) async {
    createdDisplayName = displayName;
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetEmail = email;
  }

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

void main() {
  testWidgets('shows sign-in screen when there is no session', (tester) async {
    await tester.pumpWidget(
      MyApp(authService: _TestAuthService(), enableDeepLinks: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.byKey(const Key('authAppLogo')), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
  });

  testWidgets('can switch between sign-in and account creation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MyApp(authService: _TestAuthService(), enableDeepLinks: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toggleAuthMode')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('displayNameField')), findsOneWidget);
    expect(find.text('Create Account'), findsNWidgets(2));
    expect(find.byKey(const Key('confirmationField')), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggleAuthMode')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('displayNameField')), findsNothing);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.byKey(const Key('confirmationField')), findsNothing);
  });

  testWidgets('sign-up passes the entered name to account creation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authService = _TestAuthService();
    await tester.pumpWidget(
      MyApp(authService: authService, enableDeepLinks: false),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggleAuthMode')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('displayNameField')),
      'Ada Lovelace',
    );
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'ada@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'StrongPass1!',
    );
    await tester.enterText(
      find.byKey(const Key('confirmationField')),
      'StrongPass1!',
    );
    await tester.ensureVisible(find.byKey(const Key('authSubmitButton')));
    await tester.tap(find.byKey(const Key('authSubmitButton')));
    await tester.pumpAndSettle();

    expect(authService.createdDisplayName, 'Ada Lovelace');
  });

  testWidgets('password reset sends a generic recovery message', (
    tester,
  ) async {
    final authService = _TestAuthService();
    await tester.pumpWidget(
      MyApp(authService: authService, enableDeepLinks: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('forgotPasswordButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('passwordResetEmailField')),
      'ada@example.com',
    );
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(authService.resetEmail, 'ada@example.com');
    expect(
      find.textContaining('If an account exists for this address'),
      findsOneWidget,
    );
  });

  testWidgets('sign-up rejects passwords that do not meet the policy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authService = _TestAuthService();
    await tester.pumpWidget(
      MyApp(authService: authService, enableDeepLinks: false),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggleAuthMode')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('displayNameField')),
      'Ada Lovelace',
    );
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'ada@example.com',
    );
    await tester.enterText(find.byKey(const Key('passwordField')), 'password');
    await tester.enterText(
      find.byKey(const Key('confirmationField')),
      'password',
    );
    await tester.ensureVisible(find.byKey(const Key('authSubmitButton')));
    await tester.tap(find.byKey(const Key('authSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Include at least one uppercase letter.'), findsOneWidget);
    expect(authService.createdDisplayName, isNull);
  });

  testWidgets('validates required sign-in fields', (tester) async {
    await tester.pumpWidget(
      MyApp(authService: _TestAuthService(), enableDeepLinks: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('authSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('password visibility can be toggled', (tester) async {
    await tester.pumpWidget(
      MyApp(authService: _TestAuthService(), enableDeepLinks: false),
    );
    await tester.pumpAndSettle();

    final passwordField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('passwordField')),
        matching: find.byType(EditableText),
      ),
    );
    expect(passwordField.obscureText, isTrue);

    await tester.tap(find.byKey(const Key('togglePasswordVisibility')));
    await tester.pumpAndSettle();

    final visiblePasswordField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('passwordField')),
        matching: find.byType(EditableText),
      ),
    );
    expect(visiblePasswordField.obscureText, isFalse);
  });
}
