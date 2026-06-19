import 'package:flutter/material.dart';

/// Identité visuelle KENZORF : palette noir / blanc avec un accent doré
/// sobre, typographie nette, Material 3.
class AppColors {
  const AppColors._();

  static const Color ink = Color(0xFF111111); // Noir principal
  static const Color charcoal = Color(0xFF2A2A2A);
  static const Color stone = Color(0xFF6B6B6B); // Gris texte secondaire
  static const Color mist = Color(0xFFF4F4F2); // Fond clair
  static const Color line = Color(0xFFE4E4E1); // Bordures
  static const Color paper = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFFB8893A); // Doré KENZORF
  static const Color accentDark = Color(0xFF9A7230);
  static const Color success = Color(0xFF2E7D52);
  static const Color danger = Color(0xFFB3261E);
  static const Color warning = Color(0xFFB26A00);
}

/// Construit les thèmes Material 3 (clair par défaut, sombre disponible).
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.ink,
      brightness: brightness,
      primary: isDark ? AppColors.paper : AppColors.ink,
      onPrimary: isDark ? AppColors.ink : AppColors.paper,
      secondary: AppColors.accent,
      onSecondary: AppColors.paper,
      surface: isDark ? const Color(0xFF161616) : AppColors.paper,
      error: AppColors.danger,
    );

    final TextTheme textTheme =
        Typography.material2021(platform: TargetPlatform.iOS).black.apply(
          fontFamily: 'Roboto',
          bodyColor: isDark ? AppColors.paper : AppColors.ink,
          displayColor: isDark ? AppColors.paper : AppColors.ink,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : AppColors.mist,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : AppColors.paper,
        foregroundColor: isDark ? AppColors.paper : AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: isDark ? AppColors.charcoal : AppColors.line),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: scheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1C1C1C) : AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.charcoal : AppColors.line,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : AppColors.paper,
        selectedColor: scheme.primary,
        side: BorderSide(color: isDark ? AppColors.charcoal : AppColors.line),
        labelStyle: TextStyle(color: scheme.onSurface),
        secondaryLabelStyle: TextStyle(color: scheme.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : AppColors.paper,
        selectedItemColor: scheme.primary,
        unselectedItemColor: AppColors.stone,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.charcoal : AppColors.line,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: AppColors.paper),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
