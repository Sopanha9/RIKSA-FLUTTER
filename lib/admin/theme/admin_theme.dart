import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AdminTheme {
  AdminTheme._();

  static const Color sidebarBackground = Color(0xFF152238);
  static const Color sidebarItemActive = Color(0xFF1B4332);
  static const Color sidebarItemHover = Color(0xFF1E3A5F);
  static const Color sidebarTextPrimary = Color(0xFFFFFFFF);
  static const Color sidebarTextMuted = Color(0xFF8899AA);
  static const Color contentBackground = Color(0xFFF4F6F9);

  static ThemeData get light {
    final base = AppTheme.light;

    return base.copyWith(
      scaffoldBackgroundColor: contentBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.onBackground,
        elevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.onBackground,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.onBackground),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.onBackground),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.onBackground),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.onBackground),
        bodyLarge: TextStyle(fontSize: 14, color: AppTheme.onBackground),
        bodyMedium: TextStyle(fontSize: 13, color: AppTheme.muted),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primary),
      ),
    );
  }
}
