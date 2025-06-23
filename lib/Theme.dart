import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF2E2E2E);
  static const Color titleAndButtons = Color(0xFF4A4A4A);
  static const Color textColor = Colors.white;
}

final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.titleAndButtons,
  colorScheme: ColorScheme.light(
    primary: AppColors.titleAndButtons,
    secondary: AppColors.titleAndButtons,
    background: AppColors.background,
    surface: AppColors.background,
    onPrimary: AppColors.textColor,
    onSecondary: AppColors.textColor,
    onBackground: AppColors.textColor,
    onSurface: AppColors.textColor,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.titleAndButtons,
      foregroundColor: AppColors.textColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: TextStyle(fontSize: 16),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.titleAndButtons,
    foregroundColor: AppColors.textColor,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    color: AppColors.background,
    elevation: 3,
    shadowColor: AppColors.textColor.withOpacity(0.2),
  ),
);
