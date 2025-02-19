import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6366F1);
  static const secondary = Color(0xFF4F46E5);
  static const dark100 = Color(0xFF1E1E1E);
  static const dark200 = Color(0xFF2D2D2D);
  static const dark300 = Color(0xFF3D3D3D);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF9CA3AF);
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.dark100,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textPrimary),
      bodySmall: TextStyle(color: AppColors.textSecondary),
    ),
  );
} 