import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Aegean Citrus palette. Single source of truth for the app's colors.
class AppColors {
  AppColors._();

  static const Color coral = Color(0xFFFF5436);
  static const Color coralDeep = Color(0xFFE63E22);
  static const Color teal = Color(0xFF0FB5A8);
  static const Color tealDeep = Color(0xFF0B8C82);
  static const Color amber = Color(0xFFFFC53D);
  static const Color amberArc = Color(0xFFFF9A3D);

  static const Color ink = Color(0xFF16282D);
  static const Color inkSoft = Color(0xFF5C6B6E);
  static const Color ground = Color(0xFFFFF7F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFFF0E4);
  static const Color line = Color(0x1A16282D);

  // Dark mode.
  static const Color groundDark = Color(0xFF101C20);
  static const Color surfaceDark = Color(0xFF182A30);
  static const Color surfaceAltDark = Color(0xFF22363C);
  static const Color inkDark = Color(0xFFECF2F1);
  static const Color inkSoftDark = Color(0xFF9FB0B2);
  static const Color lineDark = Color(0x1FFFFFFF);

  /// Deep ink gradient used by the grades hero card (and any dark surface).
  static const List<Color> heroGradient = [Color(0xFF1E3A40), Color(0xFF16282D)];

  /// Teal gradient used by the restaurant header.
  static const List<Color> tealGradient = [teal, tealDeep];
}

class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
}

/// Monospace "data voice" used for grades, course codes, ECTS, meal times and
/// dates. JetBrains Mono via google_fonts.
TextStyle monoStyle({
  double? fontSize,
  FontWeight fontWeight = FontWeight.w600,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.jetBrainsMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light =>
      _build(_lightScheme, AppColors.ground, AppColors.line);

  static ThemeData get dark =>
      _build(_darkScheme, AppColors.groundDark, AppColors.lineDark);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.coral,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFE0D8),
    onPrimaryContainer: Color(0xFF5A1A0E),
    secondary: AppColors.teal,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFC9F2EE),
    onSecondaryContainer: Color(0xFF06403B),
    tertiary: AppColors.amber,
    onTertiary: Color(0xFF3A2D00),
    tertiaryContainer: Color(0xFFFFE9B0),
    onTertiaryContainer: Color(0xFF3A2D00),
    error: AppColors.coralDeep,
    onError: Colors.white,
    errorContainer: Color(0xFFFFE0D8),
    onErrorContainer: Color(0xFF5A1A0E),
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.inkSoft,
    outline: Color(0xFFB9C2C2),
    outlineVariant: Color(0xFFDCE3E2),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFFDF9F4),
    surfaceContainer: Color(0xFFFBF6F0),
    surfaceContainerHigh: Color(0xFFF6F1EB),
    surfaceContainerHighest: Color(0xFFF1ECE6),
    inverseSurface: AppColors.ink,
    onInverseSurface: AppColors.ground,
    inversePrimary: Color(0xFFFFB4A2),
    shadow: Colors.black,
    scrim: Colors.black,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.coral,
    onPrimary: Color(0xFF3A0E04),
    primaryContainer: Color(0xFF7A2414),
    onPrimaryContainer: Color(0xFFFFDAD1),
    secondary: AppColors.teal,
    onSecondary: Color(0xFF00322E),
    secondaryContainer: Color(0xFF0B5F58),
    onSecondaryContainer: Color(0xFFB8F2EC),
    tertiary: AppColors.amber,
    onTertiary: Color(0xFF3A2D00),
    tertiaryContainer: Color(0xFF6B5300),
    onTertiaryContainer: Color(0xFFFFE9B0),
    error: Color(0xFFFFB4A2),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C2A18),
    onErrorContainer: Color(0xFFFFDAD1),
    surface: AppColors.surfaceDark,
    onSurface: AppColors.inkDark,
    onSurfaceVariant: AppColors.inkSoftDark,
    outline: Color(0xFF5A6B6E),
    outlineVariant: Color(0xFF34464B),
    surfaceContainerLowest: Color(0xFF0C1518),
    surfaceContainerLow: Color(0xFF152428),
    surfaceContainer: Color(0xFF192B30),
    surfaceContainerHigh: Color(0xFF22363C),
    surfaceContainerHighest: Color(0xFF2C4248),
    inverseSurface: AppColors.inkDark,
    onInverseSurface: AppColors.ink,
    inversePrimary: AppColors.coralDeep,
    shadow: Colors.black,
    scrim: Colors.black,
  );

  static ThemeData _build(ColorScheme scheme, Color scaffold, Color line) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: scheme.onSurface,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        floatingLabelStyle: const TextStyle(color: AppColors.coralDeep),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.6),
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: scheme.surface,
        collapsedBackgroundColor: scheme.surface,
        iconColor: scheme.onSurfaceVariant,
        collapsedIconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        collapsedTextColor: scheme.onSurface,
        shape: const Border(),
        collapsedShape: const Border(),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
