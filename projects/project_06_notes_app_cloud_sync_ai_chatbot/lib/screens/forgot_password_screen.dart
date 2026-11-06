import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/primary_action_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSending = false;
  String? _message;
  bool _hasSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _message = null;
    });

    try {
      await context.read<AuthProvider>().sendPasswordResetEmail(
        _emailController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _hasSent = true;
          _message =
              'If an account exists for this address, a password reset link '
              'has been sent. Check your inbox and spam folder.';
        });
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          _message = switch (error.code) {
            'network-request-failed' =>
              'Could not connect. Check your internet connection and try again.',
            'too-many-requests' =>
              'Too many requests. Wait a little while before trying again.',
            'user-not-found' =>
              'If an account exists for this address, a password reset link '
                  'has been sent. Check your inbox and spam folder.',
            _ => 'Could not send the reset email. Please try again.',
          };
          _hasSent = error.code == 'user-not-found';
        });
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reset password')),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: AppPanel(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Forgot your password?',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter the email address linked to your account. '
                          'We’ll send you a secure link to choose a new password.',
                          style: TextStyle(
                            color: AppColors.mutedInk,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          key: const Key('passwordResetEmailField'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (!RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(email)) {
                              return 'Enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        if (_message case final message?) ...[
                          const SizedBox(height: 14),
                          Text(
                            message,
                            key: const Key('passwordResetMessage'),
                            style: TextStyle(
                              color: _hasSent
                                  ? AppColors.deepBlue
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        PrimaryActionButton(
                          label: 'Send reset link',
                          icon: Icons.mark_email_read_outlined,
                          isLoading: _isSending,
                          onPressed: _isSending ? null : _sendResetEmail,
                        ),
                      ],
                    ),
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
