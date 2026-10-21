import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF20233A);
  static const mutedInk = Color(0xFF6C6E80);
  static const canvas = Color(0xFFF6F5F2);
  static const violet = Color(0xFF7868E6);
  static const softViolet = Color(0xFFEFEDFF);
  static const green = Color(0xFF398564);
  static const orange = Color(0xFFB9683D);
  static const line = Color(0xFFEAE9E6);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.violet,
    brightness: Brightness.light,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.canvas,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: AppColors.ink,
        fontSize: 29,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      titleLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleMedium: TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(
        color: AppColors.mutedInk,
        fontSize: 14,
        height: 1.45,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.canvas,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.violet, width: 1.5),
      ),
    ),
  );
}
