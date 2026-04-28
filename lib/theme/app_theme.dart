import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFE53935); // emergency red
  static const Color secondaryColor = Color(0xFF1565C0); // safety blue
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF121212),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE6E6E6),
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Color(0xFFA4A4A4),
      elevation: 12,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      surface: surfaceDark,
    ),
    scaffoldBackgroundColor: backgroundDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceDark,
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2D2D2D),
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: primaryColor,
      unselectedItemColor: Color(0xFF8F8F8F),
      elevation: 12,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
  );

  static ThemeData get lightHighContrastTheme {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFD00000),
      onPrimary: Colors.white,
      secondary: Color(0xFF005A9C),
      onSecondary: Colors.white,
      error: Color(0xFFB00020),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF000000),
      surfaceContainerHighest: Color(0xFFE9EEF5),
      onSurfaceVariant: Color(0xFF1C1C1C),
      outline: Color(0xFF000000),
      outlineVariant: Color(0xFF2E2E2E),
      primaryContainer: Color(0xFFE8EEF6),
      onPrimaryContainer: Color(0xFF000000),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      tertiary: Color(0xFF006A6A),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFF9CF1F0),
      onTertiaryContainer: Color(0xFF002020),
      inverseSurface: Color(0xFF1A1A1A),
      onInverseSurface: Color(0xFFF2F2F2),
      inversePrimary: Color(0xFFFFB4AB),
      scrim: Colors.black,
      shadow: Colors.black,
      surfaceTint: Color(0xFFD00000),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outline, width: 1.2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.outline, width: 1.2),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get darkHighContrastTheme {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFF6B6B),
      onPrimary: Color(0xFF1A0000),
      secondary: Color(0xFF90CAF9),
      onSecondary: Color(0xFF001E33),
      error: Color(0xFFFF8A80),
      onError: Color(0xFF330000),
      surface: Color(0xFF0F1115),
      onSurface: Color(0xFFFFFFFF),
      surfaceContainerHighest: Color(0xFF1A1E25),
      onSurfaceVariant: Color(0xFFE5EAF2),
      outline: Color(0xFFFFFFFF),
      outlineVariant: Color(0xFFB9C3D1),
      primaryContainer: Color(0xFF2A323F),
      onPrimaryContainer: Color(0xFFFFFFFF),
      errorContainer: Color(0xFF4D1717),
      onErrorContainer: Color(0xFFFFDAD4),
      tertiary: Color(0xFF6AE4E0),
      onTertiary: Color(0xFF00201F),
      tertiaryContainer: Color(0xFF004F4D),
      onTertiaryContainer: Color(0xFF8FF5F0),
      inverseSurface: Color(0xFFF2F4F8),
      onInverseSurface: Color(0xFF111318),
      inversePrimary: Color(0xFFB3261E),
      scrim: Colors.black,
      shadow: Colors.black,
      surfaceTint: Color(0xFFFF6B6B),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outline, width: 1.2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.outlineVariant, width: 1.2),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
