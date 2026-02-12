import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConstants {
  static const String appName = 'GitGlance';
  static const String githubApiBaseUrl = 'https://api.github.com';
  static const String bookmarkedUsersKey = 'bookmarked_users';
  static const String apiTokenKey = 'api_token';
  static const String authenticatedUserKey = 'authenticated_user';
}

class AppTheme {
  // Dark Theme Palette
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color primary = Color(0xFFBB86FC);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFCF6679);
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFE0E0E0);

  // Event Type Colors
  static const Color eventPush = Color(0xFF43A047); // Green
  static const Color eventPullRequest = Color(0xFF9C27B0); // Purple
  static const Color eventIssue = Color(0xFFFF9800); // Orange
  static const Color eventOther = Color(0xFF607D8B); // Blue Grey

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        background: background,
        surface: surface,
        primary: primary,
        secondary: secondary,
        error: error,
        onBackground: onBackground,
        onSurface: onSurface,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent, // Disable tint
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
