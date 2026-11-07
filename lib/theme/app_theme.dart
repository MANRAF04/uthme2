import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Brand constants that stay the same in light and dark.
class AppColors {
  AppColors._();

  static const Color teal = Color(0xFF0E5E66);

  /// Brighter teal for dark mode, where the brand teal is too dim on black.
  static const Color tealBright = Color(0xFF2A9DA6);
  static const Color coral = Color(0xFFFF6B5A);
  static const Color amber = Color(0xFFFFB020);

  /// Ring gradient, coral to amber, used by the grade gauge.
  static const List<Color> ringGradient = [coral, Color(0xFFFF8E3D), amber];
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;
}

/// iOS style semantic colors. Read through `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color card;
  final Color cardPressed;
  final Color label;
  final Color secondaryLabel;
  final Color tertiaryLabel;
  final Color separator;
  final Color fill;
  final Color accent;
  final Color success;
  final Color danger;
  final Color warning;
  final Color barBackground;

  const AppPalette({
    required this.background,
    required this.card,
    required this.cardPressed,
    required this.label,
    required this.secondaryLabel,
    required this.tertiaryLabel,
    required this.separator,
    required this.fill,
    required this.accent,
    required this.success,
    required this.danger,
    required this.warning,
    required this.barBackground,
  });

  static const light = AppPalette(
    background: Color(0xFFF2F2F7),
    card: Color(0xFFFFFFFF),
    cardPressed: Color(0xFFE5E5EA),
    label: Color(0xFF000000),
    secondaryLabel: Color(0x993C3C43),
    tertiaryLabel: Color(0x4D3C3C43),
    separator: Color(0x4A3C3C43),
    fill: Color(0x1F767680),
    accent: AppColors.teal,
    success: Color(0xFF34C759),
    danger: Color(0xFFFF3B30),
    warning: Color(0xFFFF9500),
    barBackground: Color(0xD9F9F9F9),
  );

  static const dark = AppPalette(
    background: Color(0xFF000000),
    card: Color(0xFF1C1C1E),
    cardPressed: Color(0xFF2C2C2E),
    label: Color(0xFFFFFFFF),
    secondaryLabel: Color(0x99EBEBF5),
    tertiaryLabel: Color(0x4DEBEBF5),
    separator: Color(0xA6545458),
    fill: Color(0x3D767680),
    accent: AppColors.tealBright,
    success: Color(0xFF30D158),
    danger: Color(0xFFFF453A),
    warning: Color(0xFFFF9F0A),
    barBackground: Color(0xCC161618),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: mix(background, other.background),
      card: mix(card, other.card),
      cardPressed: mix(cardPressed, other.cardPressed),
      label: mix(label, other.label),
      secondaryLabel: mix(secondaryLabel, other.secondaryLabel),
      tertiaryLabel: mix(tertiaryLabel, other.tertiaryLabel),
      separator: mix(separator, other.separator),
      fill: mix(fill, other.fill),
      accent: mix(accent, other.accent),
      success: mix(success, other.success),
      danger: mix(danger, other.danger),
      warning: mix(warning, other.warning),
      barBackground: mix(barBackground, other.barBackground),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

/// iOS text styles. Tracking tightens as size grows. Font family is left to
/// the platform: SF on Apple devices, Roboto on Android.
class AppText {
  AppText._();

  static const largeTitle = TextStyle(
    fontSize: 34,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
  );
  static const title2 = TextStyle(
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );
  static const title3 = TextStyle(
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );
  static const headline = TextStyle(
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );
  static const body = TextStyle(
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.3,
  );
  static const callout = TextStyle(
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
  );
  static const subheadline = TextStyle(
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
  );
  static const footnote = TextStyle(
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
  );
  static const caption = TextStyle(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w400,
  );
}

/// Grades, ECTS, times and dates: tabular figures keep columns aligned and
/// stop numbers from jittering while they animate.
TextStyle figures(TextStyle style) =>
    style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

/// Bouncing scroll on every platform, like iOS.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, AppPalette.light);

  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          brightness: brightness,
        ).copyWith(
          primary: p.accent,
          onPrimary: Colors.white,
          surface: p.card,
          onSurface: p.label,
          onSurfaceVariant: p.secondaryLabel,
          outlineVariant: p.separator,
          error: p.danger,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      extensions: [p],
      textTheme: base.textTheme.apply(
        bodyColor: p.label,
        displayColor: p.label,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: CupertinoPageTransitionsBuilder(),
        },
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: p.accent,
      ),
      dividerTheme: DividerThemeData(
        color: p.separator,
        thickness: 0.5,
        space: 0.5,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionHandleColor: p.accent,
        selectionColor: p.accent.withValues(alpha: 0.3),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.light
            ? const Color(0xFF1C1C1E)
            : const Color(0xFF3A3A3C),
        contentTextStyle: AppText.subheadline.copyWith(color: Colors.white),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.tertiaryLabel,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.success : p.fill,
        ),
      ),
    );
  }
}
