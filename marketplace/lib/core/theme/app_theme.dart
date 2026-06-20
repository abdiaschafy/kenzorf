import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identité visuelle KENZORF — mode africaine contemporaine haut de gamme
/// (Abidjan) : éditorial, confiant, premium.
///
/// Palette : Charbon, Crème, Or, Terracotta + neutres chauds.
/// Typo : un serif display fort ([Fraunces]) pour les titres, une grotesque
/// nette ([Outfit]) pour le corps. Material 3, mode clair soigné.
class AppColors {
  const AppColors._();

  // --- Marque ---
  /// Charbon profond (fonds sombres, texte fort).
  static const Color charcoal = Color(0xFF15120E);

  /// Crème (fond clair principal, "papier").
  static const Color cream = Color(0xFFF2ECE0);

  /// Or KENZORF (accent, filets, monogramme).
  static const Color gold = Color(0xFFC99A3F);

  /// Or clair (survol / dégradés subtils).
  static const Color goldLight = Color(0xFFD3A24A);

  /// Terracotta (accent chaud secondaire, promos, CTA alternatifs).
  static const Color terracotta = Color(0xFFB5532E);

  // --- Neutres chauds ---
  /// Encre : charbon légèrement adouci pour le texte courant sur crème.
  static const Color ink = Color(0xFF1B1813);

  /// Gris taupe pour le texte secondaire (contraste AA sur crème/blanc).
  static const Color taupe = Color(0xFF6E665B);

  /// Filet / bordure discrète sur fond clair.
  static const Color line = Color(0xFFDED5C5);

  /// Surface "carte" claire, légèrement plus chaude que le blanc pur.
  static const Color surface = Color(0xFFFBF8F2);

  /// Blanc cassé (galeries, aplats lumineux).
  static const Color paper = Color(0xFFFFFFFF);

  /// Crème plus profonde (sections alternées, remplissage de champs).
  static const Color sand = Color(0xFFE9E1D2);

  // --- Sémantique ---
  static const Color success = Color(0xFF2E7D52);
  static const Color danger = Color(0xFFB23A26);
  static const Color warning = Color(0xFF9A6A1C);

  // --- Compat (anciennes références éventuelles) ---
  static const Color accent = gold;
  static const Color accentDark = Color(0xFF9A7230);
  static const Color mist = cream;
  static const Color stone = taupe;
}

/// Durées et courbes de mouvement standard (cohérence globale des animations).
class AppMotion {
  const AppMotion._();

  /// Micro-interaction (états pressés, fades courts).
  static const Duration micro = Duration(milliseconds: 180);

  /// Apparition d'un élément (entrée).
  static const Duration enter = Duration(milliseconds: 420);

  /// Sortie (plus rapide que l'entrée — ressenti réactif).
  static const Duration exit = Duration(milliseconds: 260);

  /// Décalage entre éléments d'une liste/grille animée.
  static const Duration stagger = Duration(milliseconds: 55);

  /// Courbe d'entrée douce (ease-out).
  static const Curve easeEnter = Curves.easeOutCubic;

  /// Courbe expressive pour translations héro.
  static const Curve emphasized = Curves.easeOutQuart;
}

/// Espacements et rayons (rythme 4/8, radii subtils premium).
class AppSpacing {
  const AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double radiusSm = 8;
  static const double radiusMd = 14;
  static const double radiusLg = 22;
}

/// Construit le thème Material 3 KENZORF (clair soigné par défaut).
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  /// Variante sombre (charbon) — utilisée comme repli ; l'app force le clair.
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final Color background = isDark ? AppColors.charcoal : AppColors.cream;
    final Color surface = isDark ? const Color(0xFF1E1A15) : AppColors.surface;
    final Color onSurface = isDark ? AppColors.cream : AppColors.ink;
    final Color onSurfaceVariant = isDark
        ? const Color(0xFFB9AE9B)
        : AppColors.taupe;
    final Color outline = isDark ? const Color(0xFF3A332A) : AppColors.line;

    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? AppColors.cream : AppColors.charcoal,
          onPrimary: isDark ? AppColors.charcoal : AppColors.cream,
          secondary: AppColors.gold,
          onSecondary: AppColors.charcoal,
          tertiary: AppColors.terracotta,
          onTertiary: AppColors.paper,
          surface: surface,
          onSurface: onSurface,
          onSurfaceVariant: onSurfaceVariant,
          outline: outline,
          outlineVariant: outline,
          error: AppColors.danger,
        );

    // Typographie éditoriale : Fraunces (serif display) + Outfit (grotesque).
    final TextTheme base = ThemeData(brightness: brightness).textTheme;
    final TextTheme body = GoogleFonts.outfitTextTheme(base);
    final TextTheme textTheme = body
        .copyWith(
          displayLarge: GoogleFonts.fraunces(
            textStyle: base.displayLarge,
            fontWeight: FontWeight.w600,
          ),
          displayMedium: GoogleFonts.fraunces(
            textStyle: base.displayMedium,
            fontWeight: FontWeight.w600,
          ),
          displaySmall: GoogleFonts.fraunces(
            textStyle: base.displaySmall,
            fontWeight: FontWeight.w600,
          ),
          headlineLarge: GoogleFonts.fraunces(
            textStyle: base.headlineLarge,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: GoogleFonts.fraunces(
            textStyle: base.headlineMedium,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: GoogleFonts.fraunces(
            textStyle: base.headlineSmall,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: GoogleFonts.fraunces(
            textStyle: base.titleLarge,
            fontWeight: FontWeight.w600,
          ),
        )
        .apply(bodyColor: onSurface, displayColor: onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.fraunces(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: outline),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
            letterSpacing: 0.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: scheme.primary, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.goldLight : AppColors.accentDark,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF24201A) : AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: TextStyle(color: onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF24201A) : AppColors.paper,
        selectedColor: scheme.primary,
        checkmarkColor: scheme.onPrimary,
        side: BorderSide(color: outline),
        labelStyle: GoogleFonts.outfit(color: onSurface, fontSize: 13.5),
        secondaryLabelStyle: GoogleFonts.outfit(color: scheme.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      dividerTheme: DividerThemeData(
        color: outline,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        titleTextStyle: GoogleFonts.fraunces(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.outfit(color: onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.charcoal,
        contentTextStyle: GoogleFonts.outfit(
          color: AppColors.cream,
          fontSize: 14,
        ),
        actionTextColor: AppColors.goldLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold
              : onSurfaceVariant,
        ),
      ),
    );
  }
}
