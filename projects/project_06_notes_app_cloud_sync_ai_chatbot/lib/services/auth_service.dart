import 'package:firebase_auth/firebase_auth.dart';

abstract interface class AuthService {
  Stream<User?> get authStateChanges;

  User? get currentUser;

  Future<void> createAccount({
    required String displayName,
    required String email,
    required String password,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> sendPasswordResetEmail(String email);

  Future<void> updateDisplayName(String displayName);

  Future<void> updateEmail({
    required String email,
    required String currentPassword,
  });

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<void> createAccount({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Firebase created the account without returning a user.',
      );
    }
    await user.updateDisplayName(displayName.trim());
    await user.reload();
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    final user = _requireCurrentUser();
    await user.updateDisplayName(displayName.trim());
    await user.reload();
  }

  @override
  Future<void> updateEmail({
    required String email,
    required String currentPassword,
  }) async {
    final user = _requireCurrentUser();
    final currentEmail = user.email;
    if (currentEmail == null) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'This account does not have an email address.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: currentEmail,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.verifyBeforeUpdateEmail(email.trim());
    await user.reload();
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _requireCurrentUser();
    final currentEmail = user.email;
    if (currentEmail == null) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'This account does not have an email address.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: currentEmail,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
    await user.reload();
  }

  User _requireCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is signed in.',
      );
    }
    return user;
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();
}
