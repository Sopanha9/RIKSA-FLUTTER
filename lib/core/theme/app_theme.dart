import 'package:flutter/material.dart';

/// Raw color values for Riksa's warm, Cambodian-inspired visual language.
/// Feature code should prefer [RiksaPalette] so dark mode stays semantic.
class AppColors {
  AppColors._();

  static const appCanvas = Color(0xFFF9F9FB);
  static const warmCanvas = Color(0xFFFFF8EC);
  static const warmSurface = Color(0xFFFFFCF6);
  static const warmSurfaceRaised = Color(0xFFFFF2D9);
  static const ink = Color(0xFF29251C);
  static const inkMuted = Color(0xFF70695E);
  static const inkFaint = Color(0xFFA39A8C);
  static const warmOutline = Color(0xFFE8DCC7);

  static const brandJade = Color(0xFF237A5B);
  static const brandJadeStrong = Color(0xFF15543E);
  static const brandJadeSoft = Color(0xFFDDEFE5);
  static const achievementSaffron = Color(0xFFE69A18);
  static const achievementSaffronSoft = Color(0xFFFFE7B5);
  static const supportingBlush = Color(0xFFF7DCE7);
  static const supportingCream = Color(0xFFFFEDCF);

  // Editorial system colors introduced with the community/profile refresh.
  // These are additive tokens so existing feature semantics can migrate
  // without repurposing learning-success jade or achievement saffron.
  static const editorialAubergine = Color(0xFF2A061D);
  static const editorialAubergineRaised = Color(0xFF3A0A29);
  static const editorialPink = Color(0xFFEE8FD0);
  static const editorialPinkSoft = Color(0xFFF7D8EE);
  static const editorialCanvas = appCanvas;
  static const editorialSurface = Color(0xFFFFFBF7);
  static const editorialNeutralCanvas = appCanvas;
  static const editorialNeutralSurface = Color(0xFFFFFFFF);
  static const editorialField = Color(0xFFEFEFF2);
  static const editorialOutline = Color(0xFFE6E6EA);
  static const editorialInk = Color(0xFF191619);
  static const editorialMuted = Color(0xFF706C73);
  static const editorialBlack = Color(0xFF111012);
  static const editorialMint = Color(0xFFDFF2DC);
  static const editorialCreamSoft = Color(0xFFF7ECD8);
  static const editorialLavender = Color(0xFFE8E5F7);

  static const subjectMath = Color(0xFF76528F);
  static const subjectScience = Color(0xFF198A82);
  static const subjectLanguage = Color(0xFFD2674A);
  static const subjectTechnology = Color(0xFF3974A8);
  static const subjectHumanities = Color(0xFFB87824);
  static const subjectGeneral = Color(0xFF68715A);

  static const darkCanvas = Color(0xFF181713);
  static const darkSurface = Color(0xFF211F1A);
  static const darkSurfaceRaised = Color(0xFF2C2922);
  static const darkInk = Color(0xFFF8F0E3);
  static const darkInkMuted = Color(0xFFC7BDAE);
  static const darkOutline = Color(0xFF494238);
  static const error = Color(0xFFB93E3E);

  // Compatibility aliases while older screens migrate to semantic tokens.
  static const brandPrimary = brandJade;
  static const brandPrimaryHover = Color(0xFF2E8C69);
  static const brandPrimaryPressed = brandJadeStrong;
  static const brandAccent = brandJadeStrong;
  static const brandSoft = brandJadeSoft;
  static const gamificationOrange = achievementSaffron;
  static const gamificationOrangePressed = Color(0xFFAE6905);
  static const gamificationOrangeSoft = achievementSaffronSoft;
  static const gamificationGold = achievementSaffron;
  static const gamificationGoldSoft = achievementSaffronSoft;
  static const neutralInk = ink;
  static const lightCanvas = appCanvas;
  static const lightSurface = warmSurface;
  static const lightSubtle = warmSurfaceRaised;
  static const lightTextPrimary = ink;
  static const lightTextSecondary = inkMuted;
  static const lightTextTertiary = inkFaint;
  static const lightBorder = warmOutline;
  static const lightBorderStrong = Color(0xFFD5C4A8);
  static const darkSubtle = darkSurfaceRaised;
  static const darkElevated = darkSurfaceRaised;
  static const darkTextPrimary = darkInk;
  static const darkTextSecondary = darkInkMuted;
  static const darkBorder = darkOutline;
  static const success = brandJade;
  static const warning = achievementSaffron;
  static const info = subjectTechnology;
  static const socialRepost = success;
  static const socialLike = error;
}

@immutable
class RiksaPalette extends ThemeExtension<RiksaPalette> {
  const RiksaPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.outline,
    required this.jade,
    required this.jadeStrong,
    required this.jadeSoft,
    required this.saffron,
    required this.saffronSoft,
    required this.blushSoft,
    required this.creamSoft,
    required this.math,
    required this.science,
    required this.language,
    required this.technology,
    required this.humanities,
    required this.general,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;
  final Color outline;
  final Color jade;
  final Color jadeStrong;
  final Color jadeSoft;
  final Color saffron;
  final Color saffronSoft;
  final Color blushSoft;
  final Color creamSoft;
  final Color math;
  final Color science;
  final Color language;
  final Color technology;
  final Color humanities;
  final Color general;

  static const light = RiksaPalette(
    canvas: AppColors.editorialNeutralCanvas,
    surface: AppColors.editorialNeutralSurface,
    surfaceRaised: AppColors.editorialField,
    ink: AppColors.editorialInk,
    inkMuted: AppColors.editorialMuted,
    inkFaint: Color(0xFFA6A2AA),
    outline: AppColors.editorialOutline,
    jade: AppColors.brandJade,
    jadeStrong: AppColors.brandJadeStrong,
    jadeSoft: AppColors.brandJadeSoft,
    saffron: AppColors.achievementSaffron,
    saffronSoft: AppColors.achievementSaffronSoft,
    blushSoft: AppColors.supportingBlush,
    creamSoft: AppColors.supportingCream,
    math: AppColors.subjectMath,
    science: AppColors.subjectScience,
    language: AppColors.subjectLanguage,
    technology: AppColors.subjectTechnology,
    humanities: AppColors.subjectHumanities,
    general: AppColors.subjectGeneral,
  );

  static const dark = RiksaPalette(
    canvas: AppColors.darkCanvas,
    surface: AppColors.darkSurface,
    surfaceRaised: AppColors.darkSurfaceRaised,
    ink: AppColors.darkInk,
    inkMuted: AppColors.darkInkMuted,
    inkFaint: Color(0xFF958C7E),
    outline: AppColors.darkOutline,
    jade: Color(0xFF69B893),
    jadeStrong: Color(0xFF9AD4B7),
    jadeSoft: Color(0xFF243F33),
    saffron: Color(0xFFF4B84D),
    saffronSoft: Color(0xFF49391D),
    blushSoft: Color(0xFF442F38),
    creamSoft: Color(0xFF443723),
    math: Color(0xFFB49ACA),
    science: Color(0xFF69C4BC),
    language: Color(0xFFF09A82),
    technology: Color(0xFF83B5DF),
    humanities: Color(0xFFE5AE62),
    general: Color(0xFFADB69C),
  );

  @override
  RiksaPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    Color? outline,
    Color? jade,
    Color? jadeStrong,
    Color? jadeSoft,
    Color? saffron,
    Color? saffronSoft,
    Color? blushSoft,
    Color? creamSoft,
    Color? math,
    Color? science,
    Color? language,
    Color? technology,
    Color? humanities,
    Color? general,
  }) => RiksaPalette(
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    inkFaint: inkFaint ?? this.inkFaint,
    outline: outline ?? this.outline,
    jade: jade ?? this.jade,
    jadeStrong: jadeStrong ?? this.jadeStrong,
    jadeSoft: jadeSoft ?? this.jadeSoft,
    saffron: saffron ?? this.saffron,
    saffronSoft: saffronSoft ?? this.saffronSoft,
    blushSoft: blushSoft ?? this.blushSoft,
    creamSoft: creamSoft ?? this.creamSoft,
    math: math ?? this.math,
    science: science ?? this.science,
    language: language ?? this.language,
    technology: technology ?? this.technology,
    humanities: humanities ?? this.humanities,
    general: general ?? this.general,
  );

  @override
  RiksaPalette lerp(covariant RiksaPalette? other, double t) {
    if (other == null) return this;
    return RiksaPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      jade: Color.lerp(jade, other.jade, t)!,
      jadeStrong: Color.lerp(jadeStrong, other.jadeStrong, t)!,
      jadeSoft: Color.lerp(jadeSoft, other.jadeSoft, t)!,
      saffron: Color.lerp(saffron, other.saffron, t)!,
      saffronSoft: Color.lerp(saffronSoft, other.saffronSoft, t)!,
      blushSoft: Color.lerp(blushSoft, other.blushSoft, t)!,
      creamSoft: Color.lerp(creamSoft, other.creamSoft, t)!,
      math: Color.lerp(math, other.math, t)!,
      science: Color.lerp(science, other.science, t)!,
      language: Color.lerp(language, other.language, t)!,
      technology: Color.lerp(technology, other.technology, t)!,
      humanities: Color.lerp(humanities, other.humanities, t)!,
      general: Color.lerp(general, other.general, t)!,
    );
  }
}

extension RiksaThemeContext on BuildContext {
  RiksaPalette get riksa {
    final theme = Theme.of(this);
    return theme.extension<RiksaPalette>() ??
        (theme.brightness == Brightness.dark
            ? RiksaPalette.dark
            : RiksaPalette.light);
  }
}

class RiksaSpacing {
  RiksaSpacing._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadii {
  AppRadii._();
  static const double small = 8;
  static const double badge = 13;
  static const double medium = 14;
  static const double row = 16;
  static const double large = 20;
  static const double panel = 24;
  static const double extraLarge = 28;
  static const double feature = 32;
  static const double full = 9999;
  static const smallBorder = BorderRadius.all(Radius.circular(small));
  static const badgeBorder = BorderRadius.all(Radius.circular(badge));
  static const mediumBorder = BorderRadius.all(Radius.circular(medium));
  static const rowBorder = BorderRadius.all(Radius.circular(row));
  static const largeBorder = BorderRadius.all(Radius.circular(large));
  static const panelBorder = BorderRadius.all(Radius.circular(panel));
  static const extraLargeBorder = BorderRadius.all(Radius.circular(extraLarge));
  static const featureBorder = BorderRadius.all(Radius.circular(feature));
  static const fullBorder = BorderRadius.all(Radius.circular(full));
}

class RiksaElevation {
  RiksaElevation._();
  static List<BoxShadow> low(Brightness brightness) => [
    BoxShadow(
      color: Colors.black.withValues(
        alpha: brightness == Brightness.dark ? .18 : .055,
      ),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];
}

class RiksaMotion {
  RiksaMotion._();
  static const fast = Duration(milliseconds: 100);
  static const standard = Duration(milliseconds: 200);
  static const emphasis = Duration(milliseconds: 550);
  static const emphasisLong = Duration(milliseconds: 650);
  static const standardCurve = Curves.easeOutCubic;
  static const emphasisCurve = Curves.easeOutBack;

  static Duration resolve(BuildContext context, Duration duration) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false
      ? Duration.zero
      : duration;
}

class RiksaTypography {
  RiksaTypography._();
  static const latinFamily = 'Poppins';
  static const khmerFamily = 'Noto Sans Khmer';
  static const khmerTitleFamily = 'Koulen';
  static const khmerBodyFamily = 'Kantumruy Pro';
  static const fallback = <String>[khmerFamily];
  static const khmerTitleFallback = <String>[
    khmerBodyFamily,
    khmerFamily,
    latinFamily,
  ];

  static bool containsKhmer(String text) =>
      RegExp(r'[\u1780-\u17FF\u19E0-\u19FF]').hasMatch(text);

  static TextStyle? titleStyleFor(
    String text,
    TextStyle? style, {
    double khmerHeight = 1.25,
  }) {
    if (style == null || !containsKhmer(text)) return style;
    return style.copyWith(
      fontFamily: khmerTitleFamily,
      fontFamilyFallback: khmerTitleFallback,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: khmerHeight,
    );
  }

  static TextStyle? bodyStyleFor(String text, TextStyle? style) {
    if (style == null || !containsKhmer(text)) return style;
    return style.copyWith(
      fontFamily: khmerBodyFamily,
      fontFamilyFallback: const [khmerFamily, latinFamily],
      letterSpacing: 0,
    );
  }

  static TextTheme textTheme(Color ink, Color muted) => TextTheme(
    displayLarge: _style(36, FontWeight.w700, ink, 1.12),
    displayMedium: _style(32, FontWeight.w700, ink, 1.15),
    displaySmall: _style(28, FontWeight.w700, ink, 1.18),
    headlineLarge: _style(26, FontWeight.w700, ink, 1.22),
    headlineMedium: _style(23, FontWeight.w700, ink, 1.25),
    headlineSmall: _style(21, FontWeight.w700, ink, 1.27),
    titleLarge: _style(19, FontWeight.w700, ink, 1.3),
    titleMedium: _style(17, FontWeight.w600, ink, 1.35),
    titleSmall: _style(15, FontWeight.w600, ink, 1.38),
    bodyLarge: _style(16, FontWeight.w400, ink, 1.55),
    bodyMedium: _style(14, FontWeight.w400, ink, 1.55),
    bodySmall: _style(12, FontWeight.w400, muted, 1.5),
    labelLarge: _style(14, FontWeight.w600, ink, 1.35),
    labelMedium: _style(12, FontWeight.w600, ink, 1.35),
    labelSmall: _style(11, FontWeight.w600, muted, 1.35),
  );

  static TextStyle _style(
    double size,
    FontWeight weight,
    Color color,
    double height,
  ) => TextStyle(
    fontFamily: latinFamily,
    fontFamilyFallback: fallback,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

class AppTheme {
  AppTheme._();
  static const Color background = AppColors.editorialNeutralCanvas;
  static const Color surface = AppColors.editorialNeutralSurface;
  static const Color primary = AppColors.editorialAubergine;
  static const Color primaryContainer = AppColors.editorialPinkSoft;
  static const Color onPrimary = Colors.white;
  static const Color secondary = AppColors.brandJadeStrong;
  static const Color onBackground = AppColors.ink;
  static const Color onSurface = AppColors.ink;
  static const Color muted = AppColors.inkMuted;
  static const Color outline = AppColors.warmOutline;
  static const Color error = AppColors.error;
  static const Color onError = Colors.white;

  static ThemeData get light => _theme(Brightness.light, RiksaPalette.light);
  static ThemeData get dark => _theme(Brightness.dark, RiksaPalette.dark);

  static ThemeData _theme(Brightness brightness, RiksaPalette palette) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.editorialPink : AppColors.editorialAubergine,
      onPrimary: isDark ? AppColors.editorialAubergine : Colors.white,
      primaryContainer: isDark
          ? AppColors.editorialAubergineRaised
          : AppColors.editorialPinkSoft,
      onPrimaryContainer: isDark ? AppColors.editorialPinkSoft : palette.ink,
      secondary: isDark ? palette.saffron : AppColors.editorialPink,
      onSecondary: isDark ? AppColors.darkCanvas : AppColors.editorialAubergine,
      secondaryContainer: isDark
          ? palette.saffronSoft
          : AppColors.editorialPinkSoft,
      onSecondaryContainer: palette.ink,
      tertiary: palette.language,
      onTertiary: isDark ? AppColors.darkCanvas : Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: palette.surface,
      onSurface: palette.ink,
      surfaceContainer: palette.surfaceRaised,
      surfaceContainerLow: palette.surface,
      surfaceContainerHighest: palette.outline,
      onSurfaceVariant: palette.inkMuted,
      outline: palette.outline,
      outlineVariant: palette.outline,
      shadow: Colors.black,
      scrim: Colors.black.withValues(alpha: isDark ? .72 : .45),
      inverseSurface: palette.ink,
      onInverseSurface: palette.canvas,
      inversePrimary: isDark ? AppColors.brandJade : const Color(0xFF75C6A0),
    );
    final textTheme = RiksaTypography.textTheme(palette.ink, palette.inkMuted);
    const componentShape = RoundedRectangleBorder(
      borderRadius: AppRadii.largeBorder,
    );
    const inputShape = OutlineInputBorder(borderRadius: AppRadii.mediumBorder);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: RiksaTypography.latinFamily,
      fontFamilyFallback: RiksaTypography.fallback,
      colorScheme: scheme,
      extensions: [palette],
      scaffoldBackgroundColor: palette.canvas,
      canvasColor: palette.canvas,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      dividerColor: palette.outline,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: isDark
            ? AppColors.editorialPink
            : AppColors.editorialAubergine,
        selectionColor: AppColors.editorialPink.withValues(alpha: .28),
        selectionHandleColor: AppColors.editorialPink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.canvas,
        foregroundColor: palette.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(48),
          backgroundColor: palette.surface,
          foregroundColor: palette.ink,
          shape: const CircleBorder(),
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: componentShape,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceRaised,
        selectedColor: palette.jadeSoft,
        disabledColor: palette.outline,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: palette.jadeStrong,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RiksaSpacing.md,
          vertical: RiksaSpacing.md,
        ),
        border: inputShape.copyWith(borderSide: BorderSide.none),
        enabledBorder: inputShape.copyWith(borderSide: BorderSide.none),
        focusedBorder: inputShape.copyWith(
          borderSide: BorderSide(
            color: isDark
                ? AppColors.editorialPink
                : AppColors.editorialAubergine,
            width: 1.5,
          ),
        ),
        errorBorder: inputShape.copyWith(
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: inputShape.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: palette.inkMuted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.inkMuted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark
              ? AppColors.editorialPink
              : AppColors.editorialBlack,
          foregroundColor: isDark ? AppColors.editorialAubergine : Colors.white,
          disabledBackgroundColor: palette.outline,
          disabledForegroundColor: palette.inkMuted,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: RiksaSpacing.lg),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? AppColors.editorialPink
              : AppColors.editorialBlack,
          foregroundColor: isDark ? AppColors.editorialAubergine : Colors.white,
          minimumSize: const Size(0, 50),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: palette.surface,
          foregroundColor: palette.ink,
          minimumSize: const Size(0, 50),
          side: BorderSide(color: palette.outline),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark
              ? AppColors.editorialPink
              : AppColors.editorialAubergine,
          textStyle: textTheme.labelLarge,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        modalBackgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.large),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? AppColors.editorialPink : AppColors.editorialAubergine,
        linearTrackColor: isDark
            ? AppColors.editorialAubergineRaised
            : AppColors.editorialPinkSoft,
        circularTrackColor: isDark
            ? AppColors.editorialAubergineRaised
            : AppColors.editorialPinkSoft,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark
            ? AppColors.editorialPink
            : AppColors.editorialBlack,
        foregroundColor: isDark ? AppColors.editorialAubergine : Colors.white,
        elevation: 2,
      ),
    );
  }
}
