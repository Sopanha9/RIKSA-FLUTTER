import 'package:flutter/material.dart';

/// RIKSA's semantic color system.
///
/// Feature code should normally consume [Theme.of] / [ColorScheme] rather than
/// these constants directly. The named tokens remain available for accents
/// that Material's scheme does not model, such as social reactions.
class AppColors {
  AppColors._();

  // Brand green is for navigation, controls, links, and active states.
  static const brandPrimary = Color(0xFF16A34A);
  static const brandPrimaryHover = Color(0xFF22C55E);
  static const brandPrimaryPressed = Color(0xFF166534);
  static const brandAccent = Color(0xFF2E7D32);
  static const brandSoft = Color(0xFFDCFCE7);

  // Orange is intentionally reserved for streaks, XP, and achievements.
  static const gamificationOrange = Color(0xFFF97316);
  static const gamificationOrangePressed = Color(0xFFC2410C);
  static const gamificationOrangeSoft = Color(0xFFFFF1E8);
  static const gamificationGold = Color(0xFFF59E0B);
  static const gamificationGoldSoft = Color(0xFFFFF7D6);

  static const neutralInk = Color(0xFF1A1A1A);
  static const lightCanvas = Color(0xFFFAFAFA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSubtle = Color(0xFFF3F4F6);
  static const lightTextPrimary = neutralInk;
  static const lightTextSecondary = Color(0xFF6B7280);
  static const lightTextTertiary = Color(0xFF9CA3AF);
  static const lightBorder = Color(0xFFE5E7EB);
  static const lightBorderStrong = Color(0xFFD1D5DB);

  static const darkCanvas = Color(0xFF111827);
  static const darkSubtle = Color(0xFF1F2937);
  static const darkElevated = Color(0xFF18212F);
  static const darkTextPrimary = Color(0xFFF9FAFB);
  static const darkTextSecondary = Color(0xFF9CA3AF);
  static const darkBorder = Color(0xFF374151);

  static const success = brandPrimary;
  static const warning = gamificationGold;
  static const error = Color(0xFFDC2626);
  static const info = brandAccent;
  static const socialRepost = success;
  static const socialLike = error;
}

/// Corner-radius scale used by component role rather than component size.
class AppRadii {
  AppRadii._();

  static const double small = 8;
  static const double medium = 14;
  static const double large = 24;
  static const double full = 9999;

  static const BorderRadius smallBorder = BorderRadius.all(
    Radius.circular(small),
  );
  static const BorderRadius mediumBorder = BorderRadius.all(
    Radius.circular(medium),
  );
  static const BorderRadius largeBorder = BorderRadius.all(
    Radius.circular(large),
  );
  static const BorderRadius fullBorder = BorderRadius.all(
    Radius.circular(full),
  );
}

/// RIKSA application themes built from the Figma light and dark variables.
class AppTheme {
  AppTheme._();

  // Backward-compatible aliases while older screens migrate to ColorScheme.
  static const Color background = AppColors.lightCanvas;
  static const Color surface = AppColors.lightSurface;
  static const Color primary = AppColors.brandPrimary;
  static const Color primaryContainer = AppColors.brandSoft;
  static const Color onPrimary = Colors.white;
  static const Color secondary = AppColors.brandAccent;
  static const Color onBackground = AppColors.lightTextPrimary;
  static const Color onSurface = AppColors.lightTextPrimary;
  static const Color muted = AppColors.lightTextSecondary;
  static const Color outline = AppColors.lightBorder;
  static const Color error = AppColors.error;
  static const Color onError = Colors.white;

  static ThemeData get light => _theme(
    brightness: Brightness.light,
    canvas: AppColors.lightCanvas,
    surface: AppColors.lightSurface,
    surfaceContainer: AppColors.lightSubtle,
    foreground: AppColors.lightTextPrimary,
    mutedForeground: AppColors.lightTextSecondary,
    border: AppColors.lightBorder,
    borderStrong: AppColors.lightBorderStrong,
  );

  static ThemeData get dark => _theme(
    brightness: Brightness.dark,
    canvas: AppColors.darkCanvas,
    surface: AppColors.darkCanvas,
    surfaceContainer: AppColors.darkElevated,
    foreground: AppColors.darkTextPrimary,
    mutedForeground: AppColors.darkTextSecondary,
    border: AppColors.darkBorder,
    borderStrong: AppColors.lightTextSecondary,
  );

  static ThemeData _theme({
    required Brightness brightness,
    required Color canvas,
    required Color surface,
    required Color surfaceContainer,
    required Color foreground,
    required Color mutedForeground,
    required Color border,
    required Color borderStrong,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.brandPrimary,
      onPrimary: Colors.white,
      primaryContainer: isDark ? const Color(0xFF14532D) : AppColors.brandSoft,
      onPrimaryContainer: isDark
          ? const Color(0xFFBBF7D0)
          : const Color(0xFF14532D),
      secondary: AppColors.brandAccent,
      onSecondary: Colors.white,
      secondaryContainer: isDark
          ? const Color(0xFF163C23)
          : const Color(0xFFE8F5E9),
      onSecondaryContainer: isDark
          ? AppColors.darkTextPrimary
          : const Color(0xFF14532D),
      tertiary: AppColors.gamificationOrange,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: foreground,
      surfaceContainer: surfaceContainer,
      surfaceContainerLow: isDark
          ? AppColors.darkSubtle
          : AppColors.lightSubtle,
      surfaceContainerHighest: isDark
          ? AppColors.darkBorder
          : AppColors.lightBorder,
      outline: border,
      outlineVariant: borderStrong,
      shadow: Colors.black,
      scrim: isDark ? const Color(0x99111827) : const Color(0x66000000),
      inverseSurface: isDark
          ? AppColors.lightBorder
          : AppColors.lightTextPrimary,
      onInverseSurface: isDark ? AppColors.lightTextPrimary : Colors.white,
      inversePrimary: AppColors.brandPrimaryHover,
    );

    final shape = RoundedRectangleBorder(borderRadius: AppRadii.mediumBorder);
    final inputShape = OutlineInputBorder(borderRadius: AppRadii.mediumBorder);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: border,
      textTheme: ThemeData(
        brightness: brightness,
      ).textTheme.apply(bodyColor: foreground, displayColor: foreground),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.brandPrimary,
        selectionColor: Color(0x5516A34A),
        selectionHandleColor: AppColors.brandPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape.copyWith(side: BorderSide(color: border)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        selectedColor: AppColors.brandPrimary,
        disabledColor: border,
        side: BorderSide(color: borderStrong),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.fullBorder),
        labelStyle: TextStyle(color: foreground, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: inputShape.copyWith(borderSide: BorderSide(color: border)),
        enabledBorder: inputShape.copyWith(
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: inputShape.copyWith(
          borderSide: const BorderSide(
            color: AppColors.brandPrimary,
            width: 1.5,
          ),
        ),
        errorBorder: inputShape.copyWith(
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: inputShape.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: TextStyle(color: mutedForeground, fontSize: 14),
        hintStyle: TextStyle(color: mutedForeground, fontSize: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: border,
          disabledForegroundColor: mutedForeground,
          minimumSize: const Size.fromHeight(52),
          shape: shape,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: shape,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: foreground,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: borderStrong),
          shape: shape,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandPrimaryPressed,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
    );
  }
}
