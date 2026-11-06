import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, User;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../services/profile_photo_service.dart';
import '../services/password_policy.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/primary_action_button.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({
    super.key,
    required this.onSignOut,
    this.profilePhotoService,
  });

  final Future<void> Function() onSignOut;
  final ProfilePhotoService? profilePhotoService;

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentEmailPasswordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _profileFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _isSavingProfile = false;
  bool _isUpdatingEmail = false;
  bool _isUpdatingPassword = false;
  bool _isSelectingPhoto = false;
  bool _hasInitializedFields = false;
  String? _profilePhotoUrl;

  ProfilePhotoService get _photoService =>
      widget.profilePhotoService ?? FirebaseProfilePhotoService();

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _currentEmailPasswordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _initializeFields(User user) {
    if (_hasInitializedFields) return;
    _hasInitializedFields = true;
    _displayNameController.text = user.displayName ?? '';
    _emailController.text = user.email ?? '';
    _profilePhotoUrl = user.photoURL;
  }

  Future<void> _selectProfilePhoto(String userId) async {
    if (_isSelectingPhoto) return;
    final authProvider = context.read<AuthProvider>();
    setState(() => _isSelectingPhoto = true);
    try {
      final url = await _photoService.pickAndUpload(userId);
      if (url != null) {
        authProvider.refreshUser();
        if (mounted) {
          setState(() => _profilePhotoUrl = url);
          _showMessage('Your profile photo is saved to your account.');
        }
      }
    } on FirebaseException catch (error, stackTrace) {
      _reportError(error, stackTrace, 'uploading the profile photo');
      if (mounted) {
        _showMessage(
          'Could not upload your profile photo (${error.code}). '
          'Check that Firebase Storage is enabled and its rules are deployed.',
        );
      }
    } on ProfilePhotoException catch (error, stackTrace) {
      _reportError(error, stackTrace, 'validating the profile photo');
      if (mounted) _showMessage(error.message);
    } on Exception catch (error, stackTrace) {
      _reportError(error, stackTrace, 'uploading the profile photo');
      if (mounted) _showMessage('Could not upload your profile photo.');
    } finally {
      if (mounted) setState(() => _isSelectingPhoto = false);
    }
  }

  Future<void> _removeProfilePhoto(String userId) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove profile photo?'),
        content: const Text(
          'This removes your profile photo from your account on all devices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove photo'),
          ),
        ],
      ),
    );
    if (shouldRemove != true || !mounted) return;
    final authProvider = context.read<AuthProvider>();

    try {
      await _photoService.delete(userId);
      authProvider.refreshUser();
      if (mounted) {
        setState(() => _profilePhotoUrl = null);
        _showMessage('Your profile photo was removed from your account.');
      }
    } on FirebaseException catch (error, stackTrace) {
      _reportError(error, stackTrace, 'removing the profile photo');
      if (mounted) {
        _showMessage(
          'Could not remove your profile photo (${error.code}). '
          'Check your connection and Firebase Storage rules.',
        );
      }
    } on Exception catch (error, stackTrace) {
      _reportError(error, stackTrace, 'removing the profile photo');
      if (mounted) _showMessage('Could not remove your profile photo.');
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _isSavingProfile = true);
    try {
      await context.read<AuthProvider>().updateDisplayName(
        _displayNameController.text,
      );
      if (mounted) _showMessage('Your profile has been updated.');
    } on FirebaseAuthException catch (error, stackTrace) {
      _reportError(error, stackTrace, 'updating the profile');
      if (mounted) {
        _showMessage(
          '${_authErrorMessage(error.code)} '
          '(Firebase Auth: ${error.code})',
        );
      }
    } on Exception catch (error, stackTrace) {
      _reportError(error, stackTrace, 'updating the profile');
      if (mounted) _showMessage('Could not update your profile. Try again.');
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _requestEmailChange() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isUpdatingEmail = true);
    try {
      await context.read<AuthProvider>().updateEmail(
        email: _emailController.text,
        currentPassword: _currentEmailPasswordController.text,
      );
      _currentEmailPasswordController.clear();
      if (mounted) {
        _showMessage(
          'Check your new email inbox and confirm the verification link '
          'before signing in with it.',
        );
      }
    } on FirebaseAuthException catch (error, stackTrace) {
      _reportError(error, stackTrace, 'requesting an email address change');
      if (mounted) _showMessage(_authErrorMessage(error.code));
    } on Exception catch (error, stackTrace) {
      _reportError(error, stackTrace, 'requesting an email address change');
      if (mounted) _showMessage('Could not update your email. Try again.');
    } finally {
      if (mounted) setState(() => _isUpdatingEmail = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _isUpdatingPassword = true);
    try {
      await context.read<AuthProvider>().updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      if (mounted) _showMessage('Your password has been changed.');
    } on FirebaseAuthException catch (error, stackTrace) {
      _reportError(error, stackTrace, 'changing the account password');
      if (mounted) _showMessage(_authErrorMessage(error.code));
    } on Exception catch (error, stackTrace) {
      _reportError(error, stackTrace, 'changing the account password');
      if (mounted) _showMessage('Could not change your password. Try again.');
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openPortfolio() async {
    final opened = await launchUrl(
      Uri.parse('https://gods-will.netlify.app/'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      _showMessage('Could not open the portfolio link.');
    }
  }

  void _reportError(Object error, StackTrace stackTrace, String action) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'account',
        context: ErrorDescription('while $action'),
      ),
    );
  }

  String _authErrorMessage(String code) {
    return switch (code) {
      'invalid-email' => 'Enter a valid email address.',
      'email-already-in-use' => 'That email address is already in use.',
      'requires-recent-login' || 'wrong-password' || 'invalid-credential' =>
        'The current password is incorrect. Please try again.',
      'weak-password' => 'Choose a stronger password.',
      'user-not-found' => 'Your session has expired. Sign in again.',
      'network-request-failed' =>
        'Could not connect. Check your internet connection.',
      'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
      _ => 'The account could not be updated. Please try again.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Your account session has expired.')),
          );
        }
        _initializeFields(user);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Account information')),
          body: AppBackground(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
                children: [
                  _buildPhotoCard(user),
                  const SizedBox(height: 18),
                  _buildProfileCard(),
                  const SizedBox(height: 18),
                  _buildEmailCard(user),
                  const SizedBox(height: 18),
                  _buildPasswordCard(),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: widget.onSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          color: AppColors.mutedInk,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '© ${DateTime.now().year} All rights reserved by ',
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: InkWell(
                              key: const Key('portfolioLink'),
                              onTap: _openPortfolio,
                              child: const Text(
                                'AMETOWOSI Gods-Will Atsoutsè',
                                style: TextStyle(
                                  color: AppColors.blue,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoCard(User user) {
    return AppPanel(
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: AppColors.blue.withValues(alpha: 0.12),
            child: _profilePhotoUrl == null
                ? const Icon(
                    Icons.account_circle_outlined,
                    size: 52,
                    color: AppColors.blue,
                  )
                : ClipOval(
                    child: Image.network(
                      _profilePhotoUrl!,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.account_circle_outlined,
                        size: 52,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            user.displayName?.isNotEmpty == true
                ? user.displayName!
                : 'Your profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email ?? '',
            style: const TextStyle(color: AppColors.mutedInk),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('addProfilePhotoButton'),
            onPressed: _isSelectingPhoto
                ? null
                : () => _selectProfilePhoto(user.uid),
            icon: _isSelectingPhoto
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_a_photo_outlined),
            label: Text(
              _profilePhotoUrl == null
                  ? 'Add profile photo'
                  : 'Change profile photo',
            ),
          ),
          if (_profilePhotoUrl != null)
            TextButton(
              key: const Key('removeProfilePhotoButton'),
              onPressed: _isSelectingPhoto
                  ? null
                  : () => _removeProfilePhoto(user.uid),
              child: const Text('Remove profile photo'),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return AppPanel(
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('Personal information'),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('accountDisplayNameField'),
              controller: _displayNameController,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Display name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a display name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            PrimaryActionButton(
              label: 'Save profile',
              icon: Icons.check,
              isLoading: _isSavingProfile,
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailCard(User user) {
    return AppPanel(
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('Email address'),
            const SizedBox(height: 8),
            Text(
              'Current email: ${user.email ?? 'Not available'}',
              style: const TextStyle(color: AppColors.mutedInk),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('accountEmailField'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'New email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                  return 'Enter a valid email address.';
                }
                if (email == user.email) return 'This is already your email.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('currentEmailPasswordField'),
              controller: _currentEmailPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your current password to change your email.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            PrimaryActionButton(
              label: 'Send email verification',
              icon: Icons.mark_email_read_outlined,
              isLoading: _isUpdatingEmail,
              onPressed: _requestEmailChange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard() {
    return AppPanel(
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('Change password'),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('currentPasswordField'),
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your current password.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('newPasswordField'),
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              validator: (value) {
                final policyError = validateStrongPassword(value);
                if (policyError != null) return policyError;
                if (value == _currentPasswordController.text) {
                  return 'Choose a password different from your current one.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            PrimaryActionButton(
              label: 'Update password',
              icon: Icons.key,
              isLoading: _isUpdatingPassword,
              onPressed: _changePassword,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
