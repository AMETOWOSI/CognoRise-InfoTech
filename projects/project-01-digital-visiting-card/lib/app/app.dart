import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import '../profile/data/profile_repository.dart';
import '../profile/screens/about_screen.dart';
import '../profile/screens/contact_screen.dart';
import '../profile/screens/edit_profile_screen.dart';
import '../profile/screens/home_screen.dart';
import '../profile/screens/skills_screen.dart';
import '../profile/state/profile_controller.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.repository});

  final ProfileRepository? repository;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ProfileController _profileController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _profileController = ProfileController(
      repository: widget.repository ?? SharedPreferencesProfileRepository(),
    );
    unawaited(_profileController.load());
    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              HomeScreen(profileController: _profileController),
        ),
        GoRoute(
          path: '/about',
          builder: (context, state) =>
              AboutScreen(profileController: _profileController),
        ),
        GoRoute(
          path: '/skills',
          builder: (context, state) =>
              SkillsScreen(profileController: _profileController),
        ),
        GoRoute(
          path: '/contact',
          builder: (context, state) =>
              ContactScreen(profileController: _profileController),
        ),
        GoRoute(
          path: '/edit',
          builder: (context, state) =>
              EditProfileScreen(profileController: _profileController),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _profileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      primary: AppColors.purple,
      secondary: AppColors.yellow,
      surface: Colors.white,
    );

    return MaterialApp.router(
      title: 'Digital Visiting Card',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.canvas,
        fontFamily: 'Manrope',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.canvas,
          foregroundColor: AppColors.ink,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.canvas,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE8E2EF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}
