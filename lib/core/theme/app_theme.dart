import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1A6BCC);
  static const primaryDark = Color(0xFF0D47A1);
  static const primaryLight = Color(0xFF2196F3);
  static const accent = Color(0xFF64B5F6);
  static const background = Color(0xFF0A0E1A);
  static const surface = Color(0xFF111827);
  static const surfaceVariant = Color(0xFF1C2333);
  static const cardBg = Color(0xFF161D2F);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0BEC5);
  static const textMuted = Color(0xFF607D8B);
  static const gold = Color(0xFFFFD700);
  static const error = Color(0xFFEF5350);
}

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.surface,
    error: AppColors.error,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: AppColors.textPrimary),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(color: AppColors.textPrimary),
    bodyLarge: TextStyle(color: AppColors.textSecondary),
    bodyMedium: TextStyle(color: AppColors.textSecondary),
    labelLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF2D3748)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF2D3748)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    hintStyle: const TextStyle(color: AppColors.textMuted),
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardBg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 4,
  ),
);
