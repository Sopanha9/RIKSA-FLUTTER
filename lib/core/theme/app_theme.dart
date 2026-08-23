import 'package:flutter/material.dart';

/// RIKSA's semantic color system, mirrored from the Figma variable collection.
///
/// Feature code should normally consume [Theme.of] / [ColorScheme] rather than
/// these constants directly. The named tokens remain available for accents
/// that Material's scheme does not model, such as social reactions.
class AppColors {
  AppColors._();

  static const brandPrimary = Color.fromARGB(255, 64, 73, 67);
  static const brandPrimaryHover = Color(0xFF16A34A);
  static const brandPrimaryPressed = Color(0xFF15803D);
  static const brandAccent = Color(0xFF1D9BF0);

  static const lightCanvas = Color(0xFFFFFFFF);
  static const lightSubtle = Color(0xFFF7F9F9);
  static const lightTextPrimary = Color(0xFF0F1419);
  static const lightTextSecondary = Color(0xFF536471);
  static const lightTextTertiary = Color(0xFF8B98A5);
  static const lightBorder = Color(0xFFEFF3F4);
  static const lightBorderStrong = Color(0xFFCFD9DE);

  static const darkCanvas = Color(0xFF000000);
  static const darkSubtle = Color(0xFF080808);
  static const darkElevated = Color(0xFF16181C);
  static const darkTextPrimary = Color(0xFFE7E9EA);
  static const darkTextSecondary = Color(0xFF71767B);
  static const darkBorder = Color(0xFF2F3336);

  static const success = Color(0xFF00BA7C);
  static const warning = Color(0xFFFFD400);
  static const error = Color(0xFFF91880);
  static const info = brandAccent;
  static const socialRepost = success;
  static const socialLike = error;
}

/// RIKSA application themes built from the Figma light and dark variables.
class AppTheme {
  AppTheme._();

  // Backward-compatible aliases while older screens migrate to ColorScheme.
  static const Color background = AppColors.lightCanvas;
  static const Color surface = AppColors.lightCanvas;
  static const Color primary = AppColors.brandPrimary;
  static const Color primaryContainer = AppColors.brandPrimaryHover;
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
    surface: AppColors.lightCanvas,
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
      primaryContainer: isDark
          ? const Color(0xFF062E24)
          : const Color(0xFFE7F9F2),
      onPrimaryContainer: isDark
          ? AppColors.darkTextPrimary
          : AppColors.brandPrimaryPressed,
      secondary: AppColors.brandAccent,
      onSecondary: Colors.white,
      secondaryContainer: isDark
          ? const Color(0xFF08263A)
          : const Color(0xFFE8F5FD),
      onSecondaryContainer: isDark
          ? AppColors.darkTextPrimary
          : const Color(0xFF0C5E91),
      tertiary: AppColors.success,
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
      scrim: isDark ? const Color(0x995B7083) : const Color(0x66000000),
      inverseSurface: isDark
          ? AppColors.lightBorder
          : AppColors.lightTextPrimary,
      onInverseSurface: isDark ? AppColors.lightTextPrimary : Colors.white,
      inversePrimary: AppColors.brandPrimary,
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    final inputShape = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
    );

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
        selectionColor: Color(0x3322C55E),
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
        backgroundColor: surface,
        selectedColor: AppColors.brandPrimary,
        disabledColor: border,
        side: BorderSide(color: borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
