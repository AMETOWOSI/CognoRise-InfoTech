import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, User;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/profile_photo_service.dart';
import '../services/note_reminder_service.dart';
import '../theme/app_theme.dart';
import 'account_info_screen.dart';
import 'chat_screen.dart';
import 'notes_screen.dart';

class NotesHomeScreen extends StatefulWidget {
  const NotesHomeScreen({
    super.key,
    required this.user,
    required this.reminderService,
    this.profilePhotoService,
  });

  final User user;
  final NoteReminderService reminderService;
  final ProfilePhotoService? profilePhotoService;

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  int _selectedIndex = 0;
  late final ProfilePhotoService _profilePhotoService =
      widget.profilePhotoService ?? LocalProfilePhotoService();
  String? _profilePhotoPath;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProfilePhoto());
  }

  @override
  void didUpdateWidget(covariant NotesHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _profilePhotoPath = null;
      unawaited(_loadProfilePhoto());
    }
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final path = await _profilePhotoService.loadLocalPhoto(widget.user.uid);
      if (mounted) setState(() => _profilePhotoPath = path);
    } on Exception catch (error, stackTrace) {
      _reportProfilePhotoError(error, stackTrace);
    }
  }

  void _reportProfilePhotoError(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'account',
        context: ErrorDescription('while loading the local profile photo'),
      ),
    );
  }

  void _onProfilePhotoChanged(String? path) {
    if (mounted) setState(() => _profilePhotoPath = path);
  }

  Future<void> _signOut() async {
    try {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (error, stackTrace) {
      _reportSignOutError(error, stackTrace);
      if (mounted) _showSignOutError('Could not sign out. Please try again.');
    } on Exception catch (error, stackTrace) {
      _reportSignOutError(error, stackTrace);
      if (mounted) _showSignOutError('An unexpected error occurred.');
    }
  }

  void _reportSignOutError(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'authentication',
        context: ErrorDescription('while signing out'),
      ),
    );
  }

  void _showSignOutError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _openAccountInfo() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountInfoScreen(
          onSignOut: _signOut,
          profilePhotoService: _profilePhotoService,
          onProfilePhotoChanged: _onProfilePhotoChanged,
        ),
      ),
    );
  }

  void _showNotifications() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.notifications_none, color: AppColors.blue),
        title: const Text('Notifications'),
        content: const Text(
          "You're all caught up. New notifications will appear here.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardIsVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user ?? widget.user;
          return IndexedStack(
            index: _selectedIndex,
            children: [
              NotesScreen(
                userName: user.displayName,
                userEmail: user.email,
                userPhotoPath: _profilePhotoPath,
                userId: user.uid,
                reminderService: widget.reminderService,
                onAccountTap: _openAccountInfo,
                onNotificationsTap: _showNotifications,
              ),
              ChatScreen(
                onAccountTap: _openAccountInfo,
                onNotificationsTap: _showNotifications,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: keyboardIsVisible
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.sticky_note_2_outlined),
                  selectedIcon: Icon(Icons.sticky_note_2),
                  label: 'Notes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome),
                  label: 'AI chat',
                ),
              ],
            ),
    );
  }
}
