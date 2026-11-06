import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/password_policy.dart';
import 'forgot_password_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _isCreatingAccount = false;
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      if (_isCreatingAccount) {
        await auth.createAccount(
          displayName: _displayNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await auth.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _authErrorMessage(error.code));
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'authentication',
          context: ErrorDescription('while signing in or creating an account'),
        ),
      );
      if (mounted) {
        setState(() {
          _errorMessage = 'Something went wrong. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _authErrorMessage(String code) {
    return switch (code) {
      'invalid-email' => 'Please enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Incorrect email address or password.',
      'email-already-in-use' => 'An account already exists for this email.',
      'weak-password' => 'Please choose a stronger password.',
      'operation-not-allowed' =>
        'Email sign-in is not enabled in Firebase yet.',
      'too-many-requests' => 'Too many attempts. Please wait and try again.',
      'network-request-failed' =>
        'Could not connect. Check your internet connection.',
      _ => 'Sign-in failed. Check your details and try again.',
    };
  }

  void _toggleMode() {
    setState(() {
      _isCreatingAccount = !_isCreatingAccount;
      _errorMessage = null;
      _passwordController.clear();
      _confirmationController.clear();
      _isPasswordVisible = false;
    });
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.mutedInk, fontSize: 15),
      prefixIcon: Icon(icon, color: AppColors.mutedInk, size: 23),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.62),
      contentPadding: const EdgeInsets.symmetric(vertical: 21, horizontal: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.88)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
    );
  }

  Widget _fieldSurface({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8097C8).withValues(alpha: 0.17),
            blurRadius: 19,
            offset: const Offset(8, 9),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.86),
            blurRadius: 16,
            offset: const Offset(-7, -7),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [AppColors.blue, AppColors.deepBlue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 12,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('authSubmitButton'),
          onTap: _isSubmitting ? null : _submit,
          borderRadius: BorderRadius.circular(34),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isSubmitting)
                  const SizedBox(
                    height: 23,
                    width: 23,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Text(
                    _isCreatingAccount ? 'Create Account' : 'Login',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (!_isSubmitting)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.sizeOf(context).height < 760;
    final headerSize = isSmallScreen ? 108.0 : 132.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 28,
                vertical: isSmallScreen ? 18 : 30,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          key: const Key('appLogoBadge'),
                          height: headerSize,
                          width: headerSize,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(38),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF8299C9,
                                ).withValues(alpha: 0.22),
                                blurRadius: 28,
                                offset: const Offset(12, 14),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.9),
                                blurRadius: 25,
                                offset: const Offset(-10, -10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(headerSize * 0.12),
                            child: Image.asset(
                              key: const Key('authAppLogo'),
                              'assets/branding/notes_app_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 22 : 30),
                      Text(
                        _isCreatingAccount ? 'Create Account' : 'Welcome Back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: isSmallScreen ? 31 : 37,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isCreatingAccount
                            ? 'Sign up to start organizing your notes'
                            : 'Sign in to continue',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.mutedInk,
                          fontSize: 14,
                          letterSpacing: 4,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 26 : 38),
                      if (_isCreatingAccount) ...[
                        _fieldSurface(
                          child: TextFormField(
                            key: const Key('displayNameField'),
                            controller: _displayNameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            style: const TextStyle(color: AppColors.ink),
                            decoration: _fieldDecoration(
                              hint: 'Full name',
                              icon: Icons.badge_outlined,
                            ),
                            validator: (value) {
                              if (!_isCreatingAccount) return null;
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your name.';
                              }
                              if (value.trim().length > 60) {
                                return 'Use 60 characters or fewer.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 17),
                      ],
                      _fieldSurface(
                        child: TextFormField(
                          key: const Key('emailField'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          style: const TextStyle(color: AppColors.ink),
                          decoration: _fieldDecoration(
                            hint: 'Email address',
                            icon: Icons.person_outline,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter your email address.';
                            }
                            if (!value.trim().contains('@')) {
                              return 'Enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 17),
                      _fieldSurface(
                        child: TextFormField(
                          key: const Key('passwordField'),
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          textInputAction: _isCreatingAccount
                              ? TextInputAction.next
                              : TextInputAction.done,
                          autofillHints: _isCreatingAccount
                              ? const [AutofillHints.newPassword]
                              : const [AutofillHints.password],
                          style: const TextStyle(color: AppColors.ink),
                          decoration: _fieldDecoration(
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              key: const Key('togglePasswordVisibility'),
                              tooltip: _isPasswordVisible
                                  ? 'Hide password'
                                  : 'Show password',
                              onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.mutedInk,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your password.';
                            }
                            if (_isCreatingAccount) {
                              return validateStrongPassword(value);
                            }
                            return null;
                          },
                        ),
                      ),
                      if (!_isCreatingAccount)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            key: const Key('forgotPasswordButton'),
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  ),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                      if (_isCreatingAccount) ...[
                        const SizedBox(height: 17),
                        _fieldSurface(
                          child: TextFormField(
                            key: const Key('confirmationField'),
                            controller: _confirmationController,
                            obscureText: !_isPasswordVisible,
                            textInputAction: TextInputAction.done,
                            style: const TextStyle(color: AppColors.ink),
                            decoration: _fieldDecoration(
                              hint: 'Confirm password',
                              icon: Icons.lock_outline,
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          key: const Key('authError'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      SizedBox(height: isSmallScreen ? 23 : 30),
                      _buildSubmitButton(),
                      const SizedBox(height: 19),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _isCreatingAccount
                                ? 'Already have an account? '
                                : 'New to NoteFlow? ',
                            style: const TextStyle(color: AppColors.mutedInk),
                          ),
                          TextButton(
                            onPressed: _isSubmitting ? null : _toggleMode,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.blue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                            ),
                            child: Text(
                              _isCreatingAccount ? 'Login' : 'Sign up',
                              key: const Key('toggleAuthMode'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
