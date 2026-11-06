import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

enum AuthStatus { loading, signedOut, signedIn, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService) {
    _subscription = _authService.authStateChanges.listen(
      (user) {
        _user = user;
        _status = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'authentication',
            context: ErrorDescription(
              'while listening for authentication changes',
            ),
          ),
        );
        _status = AuthStatus.error;
        _errorMessage =
            'Could not verify your session. Check your connection and try again.';
        notifyListeners();
      },
    );
  }

  final AuthService _authService;
  late final StreamSubscription<User?> _subscription;
  User? _user;
  AuthStatus _status = AuthStatus.loading;
  String? _errorMessage;

  User? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> createAccount({
    required String displayName,
    required String email,
    required String password,
  }) async {
    await _authService.createAccount(
      displayName: displayName,
      email: email,
      password: password,
    );
    _refreshCurrentUser();
  }

  Future<void> signIn({required String email, required String password}) {
    return _authService.signIn(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _authService.sendPasswordResetEmail(email);
  }

  Future<void> updateDisplayName(String displayName) async {
    await _authService.updateDisplayName(displayName);
    _refreshCurrentUser();
  }

  Future<void> updateEmail({
    required String email,
    required String currentPassword,
  }) async {
    await _authService.updateEmail(
      email: email,
      currentPassword: currentPassword,
    );
    _refreshCurrentUser();
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _authService.updatePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    _refreshCurrentUser();
  }

  void refreshUser() {
    _user = _authService.currentUser;
    notifyListeners();
  }

  void _refreshCurrentUser() {
    _user = _authService.currentUser;
    notifyListeners();
  }

  Future<void> signOut() => _authService.signOut();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
