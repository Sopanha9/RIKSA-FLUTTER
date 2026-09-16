import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

/// Raw color values for Riksa's violet, lavender and lime visual language.
/// Feature code should prefer [RiksaPalette] so dark mode stays semantic.
class AppColors {
  AppColors._();

  // Riksa violet system. Violet leads every primary action, lavender carries
  // the ground and quiet fills, lime is kept for rewards and "you" moments,
  // and the deep ink anchors dark cards and headings.
  static const violet = Color(0xFF7657EE);
  static const violetStrong = Color(0xFF5B3FD6);
  static const violetSoft = Color(0xFFEDE8FE);
  static const violetTint = Color(0xFFF7F5FE);
  static const violetDarkSoft = Color(0xFF2A273A);
  static const lime = Color(0xFFD5F06A);

  /// The fresh green of a lesson progress bar on the reference board.
  static const progressGreen = Color(0xFF8BCF4E);
  static const limeSoft = Color(0xFFEEF8C6);
  static const limeInk = Color(0xFF3F4A0E);
  static const deepInk = Color(0xFF1D1533);
  static const deepInkRaised = Color(0xFF2B2247);

  static const appCanvas = Color(0xFFFCFBFF);
  static const warmCanvas = appCanvas;
  static const warmSurface = Color(0xFFFFFFFF);
  static const warmSurfaceRaised = Color(0xFFF3F0FB);
  static const ink = Color(0xFF1D1533);
  static const inkMuted = Color(0xFF6E6886);
  static const inkFaint = Color(0xFFA7A1BA);
  static const warmOutline = Color(0xFFE8E4F3);

  static const brandJade = Color(0xFF237A5B);
  static const brandJadeStrong = Color(0xFF15543E);

  /// Jade-tinted near-white for text on a filled jade surface.
  static const jadeContrast = Color(0xFFF6FBF8);
  static const brandJadeSoft = Color(0xFFDDEFE5);
  static const achievementSaffron = Color(0xFFE69A18);
  static const achievementSaffronSoft = Color(0xFFFFE7B5);
  static const supportingBlush = Color(0xFFF7DCE7);
  static const supportingCream = Color(0xFFFFEDCF);

  // The editorial names predate the violet system; they now resolve to it so
  // every screen that still uses them follows the new look.
  static const editorialAubergine = violet;
  static const editorialAubergineRaised = darkSurfaceRaised;
  static const editorialPink = Color(0xFF9D86F7);
  static const editorialPinkSoft = violetSoft;
  static const editorialCanvas = appCanvas;
  static const editorialSurface = Color(0xFFFFFFFF);
  static const editorialNeutralCanvas = appCanvas;
  static const editorialNeutralSurface = Color(0xFFFFFFFF);
  static const editorialField = Color(0xFFF4F2FB);
  static const editorialOutline = warmOutline;
  static const editorialInk = ink;
  static const editorialMuted = inkMuted;
  static const editorialBlack = deepInk;
  static const editorialMint = limeSoft;
  static const editorialCreamSoft = Color(0xFFFFF1CF);
  static const editorialLavender = violetSoft;

  // Pastel subject tiles from the reference sheet.
  static const tileGreen = Color(0xFFE3F5D5);
  static const tileLavender = Color(0xFFEAE4FD);
  static const tilePink = Color(0xFFFCE3EF);
  static const tileBlue = Color(0xFFDDEFFB);
  static const tileYellow = Color(0xFFFFF0C9);
  static const tilePeach = Color(0xFFFFE3DA);
  static const tileMint = Color(0xFFDDF5EA);

  static const subjectMath = Color(0xFF76528F);
  static const subjectScience = Color(0xFF198A82);
  static const subjectLanguage = Color(0xFFD2674A);
  static const subjectTechnology = Color(0xFF3974A8);
  static const subjectHumanities = Color(0xFFB87824);
  static const subjectGeneral = Color(0xFF68715A);

  // Dark mode is neutral: near-black ground and graphite surfaces, with violet
  // kept for accents only, so the screen reads as dark rather than purple.
  // No text is ever pure white.
  static const darkCanvas = Color(0xFF111113);
  static const darkSurface = Color(0xFF1B1B1F);
  static const darkSurfaceRaised = Color(0xFF26262B);
  static const darkInk = Color(0xFFEDEDF0);
  static const darkInkMuted = Color(0xFF9B9BA4);
  static const darkOutline = Color(0xFF2F2F35);
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
    required this.onJade,
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
    required this.brand,
    required this.brandStrong,
    required this.brandSoft,
    required this.onBrand,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.anchor,
    required this.onAnchor,
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

  /// Text and icons drawn on a filled [jade] surface, never pure white.
  final Color onJade;
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

  /// Violet: primary actions, selection and links.
  final Color brand;
  final Color brandStrong;
  final Color brandSoft;
  final Color onBrand;

  /// Lime: rewards, streaks and the learner's own row.
  final Color accent;
  final Color accentSoft;
  final Color onAccent;

  /// Deep ink: stats cards and other dark anchors on the light ground.
  final Color anchor;
  final Color onAnchor;

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
    jadeSoft: AppColors.tileGreen,
    onJade: AppColors.jadeContrast,
    saffron: AppColors.achievementSaffron,
    saffronSoft: AppColors.tileYellow,
    blushSoft: AppColors.tilePink,
    creamSoft: AppColors.supportingCream,
    math: AppColors.subjectMath,
    science: AppColors.subjectScience,
    language: AppColors.subjectLanguage,
    technology: AppColors.subjectTechnology,
    humanities: AppColors.subjectHumanities,
    general: AppColors.subjectGeneral,
    brand: AppColors.violet,
    brandStrong: AppColors.violetStrong,
    brandSoft: AppColors.violetSoft,
    onBrand: Color(0xFFFFFFFF),
    accent: AppColors.lime,
    accentSoft: AppColors.limeSoft,
    onAccent: AppColors.limeInk,
    anchor: AppColors.deepInk,
    onAnchor: Color(0xFFF4F1FF),
  );

  static const dark = RiksaPalette(
    canvas: AppColors.darkCanvas,
    surface: AppColors.darkSurface,
    surfaceRaised: AppColors.darkSurfaceRaised,
    ink: AppColors.darkInk,
    inkMuted: AppColors.darkInkMuted,
    inkFaint: Color(0xFF5C5C64),
    outline: AppColors.darkOutline,
    jade: Color(0xFF69B893),
    jadeStrong: Color(0xFF9AD4B7),
    // Each soft fill is its own hue composited back onto the raised surface, so
    // a state tint lifts off the black ground rather than floating on it.
    jadeSoft: Color(0xFF283B36),
    // Not the canvas: that is pure black now, and the black exception is for
    // the ground only. Text keeps a near-black.
    onJade: AppColors.darkSurface,
    saffron: Color(0xFFF4B84D),
    saffronSoft: Color(0xFF504229),
    blushSoft: Color(0xFF463244),
    creamSoft: Color(0xFF4C3F2E),
    math: Color(0xFFB49ACA),
    science: Color(0xFF69C4BC),
    language: Color(0xFFF09A82),
    technology: Color(0xFF83B5DF),
    humanities: Color(0xFFE5AE62),
    general: Color(0xFFADB69C),
    brand: Color(0xFF9D86F7),
    brandStrong: Color(0xFFBBA9FA),
    brandSoft: AppColors.violetDarkSoft,
    onBrand: Color(0xFF140E24),
    accent: Color(0xFFD5F06A),
    accentSoft: Color(0xFF34391C),
    onAccent: Color(0xFF1F2408),
    anchor: AppColors.darkSurfaceRaised,
    onAnchor: AppColors.darkInk,
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
    Color? onJade,
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
    Color? brand,
    Color? brandStrong,
    Color? brandSoft,
    Color? onBrand,
    Color? accent,
    Color? accentSoft,
    Color? onAccent,
    Color? anchor,
    Color? onAnchor,
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
    onJade: onJade ?? this.onJade,
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
    brand: brand ?? this.brand,
    brandStrong: brandStrong ?? this.brandStrong,
    brandSoft: brandSoft ?? this.brandSoft,
    onBrand: onBrand ?? this.onBrand,
    accent: accent ?? this.accent,
    accentSoft: accentSoft ?? this.accentSoft,
    onAccent: onAccent ?? this.onAccent,
    anchor: anchor ?? this.anchor,
    onAnchor: onAnchor ?? this.onAnchor,
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
      onJade: Color.lerp(onJade, other.onJade, t)!,
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
      brand: Color.lerp(brand, other.brand, t)!,
      brandStrong: Color.lerp(brandStrong, other.brandStrong, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      anchor: Color.lerp(anchor, other.anchor, t)!,
      onAnchor: Color.lerp(onAnchor, other.onAnchor, t)!,
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
  static const double large = 16;
  static const double panel = 20;
  static const double extraLarge = 28;
  static const double feature = 24;
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

  /// Delay added per row when a list assembles itself.
  ///
  /// Small on purpose: the point is that the screen builds rather than blinks
  /// into place, not that the learner watches it build.
  static const stagger = Duration(milliseconds: 30);
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
  static const khmerLegacyBodyFamily = 'Kantumruy Pro';
  static const khmerBodyFamily = 'Khmer OS Siemreap';
  static const fallback = <String>[khmerFamily];
  static const khmerTitleFallback = <String>[
    khmerBodyFamily,
    khmerLegacyBodyFamily,
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
      fontFamilyFallback: const [
        khmerLegacyBodyFamily,
        khmerFamily,
        latinFamily,
      ],
      letterSpacing: 0,
    );
  }

  static TextTheme textTheme(Color ink, Color muted) => TextTheme(
    displayLarge: _style(36, FontWeight.w700, ink, 1.12),
    displayMedium: _style(32, FontWeight.w700, ink, 1.15),
    displaySmall: _style(24, FontWeight.w600, ink, 1.18),
    headlineLarge: _style(22, FontWeight.w600, ink, 1.22),
    headlineMedium: _style(20, FontWeight.w600, ink, 1.25),
    headlineSmall: _style(18, FontWeight.w600, ink, 1.27),
    titleLarge: _style(16, FontWeight.w600, ink, 1.3),
    titleMedium: _style(16, FontWeight.w600, ink, 1.35),
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
  static const Color primaryContainer = AppColors.violetSoft;
  static const Color onPrimary = Colors.white;
  static const Color secondary = AppColors.lime;
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
      primary: palette.brand,
      onPrimary: palette.onBrand,
      primaryContainer: palette.brandSoft,
      onPrimaryContainer: isDark ? palette.brandStrong : AppColors.violetStrong,
      secondary: palette.accent,
      onSecondary: palette.onAccent,
      secondaryContainer: palette.accentSoft,
      onSecondaryContainer: isDark ? palette.accent : palette.onAccent,
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
      inversePrimary: isDark ? AppColors.violet : AppColors.editorialPink,
    );
    final textTheme = RiksaTypography.textTheme(palette.ink, palette.inkMuted);
    const componentShape = RoundedRectangleBorder(
      borderRadius: AppRadii.largeBorder,
    );
    const inputShape = OutlineInputBorder(borderRadius: AppRadii.mediumBorder);
    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: RiksaPageTransitionsBuilder(
            predictiveBack: true,
          ),
          TargetPlatform.iOS: RiksaPageTransitionsBuilder(cupertino: true),
          TargetPlatform.macOS: RiksaPageTransitionsBuilder(),
          TargetPlatform.windows: RiksaPageTransitionsBuilder(),
          TargetPlatform.linux: RiksaPageTransitionsBuilder(),
          TargetPlatform.fuchsia: RiksaPageTransitionsBuilder(),
        },
      ),
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
        cursorColor: palette.brand,
        selectionColor: palette.brand.withValues(alpha: .24),
        selectionHandleColor: palette.brand,
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
        backgroundColor: palette.surface,
        selectedColor: palette.brand,
        disabledColor: palette.outline,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium?.copyWith(color: palette.inkMuted),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: palette.onBrand,
        ),
        checkmarkColor: palette.onBrand,
      ),
      // Fields sit on white with a hairline, the way the reference draws them.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        prefixIconColor: palette.inkMuted,
        suffixIconColor: palette.inkMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RiksaSpacing.md,
          vertical: RiksaSpacing.md,
        ),
        border: inputShape.copyWith(
          borderSide: BorderSide(color: palette.outline),
        ),
        enabledBorder: inputShape.copyWith(
          borderSide: BorderSide(color: palette.outline),
        ),
        disabledBorder: inputShape.copyWith(
          borderSide: BorderSide(color: palette.outline.withValues(alpha: .6)),
        ),
        focusedBorder: inputShape.copyWith(
          borderSide: BorderSide(color: palette.brand, width: 1.5),
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
          backgroundColor: palette.brand,
          foregroundColor: palette.onBrand,
          disabledBackgroundColor: palette.outline,
          disabledForegroundColor: palette.inkMuted,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: RiksaSpacing.lg),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.anchor,
          foregroundColor: palette.onAnchor,
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: palette.surface,
          foregroundColor: palette.ink,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: palette.outline),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.brand,
          textStyle: textTheme.labelLarge,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: palette.surface,
          foregroundColor: palette.inkMuted,
          selectedBackgroundColor: palette.brand,
          selectedForegroundColor: palette.onBrand,
          side: BorderSide.none,
          shape: const StadiumBorder(),
          textStyle: textTheme.labelMedium,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: palette.onBrand,
        unselectedLabelColor: palette.inkMuted,
        labelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: palette.brand,
          borderRadius: AppRadii.fullBorder,
        ),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.onBrand
              : palette.inkFaint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.brand
              : palette.surfaceRaised,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.brand
              : palette.inkFaint,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.brand
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(palette.onBrand),
        side: BorderSide(color: palette.inkFaint, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.smallBorder),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.ink,
        textColor: palette.ink,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rowBorder),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.anchor,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: palette.onAnchor,
        ),
        actionTextColor: palette.accent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rowBorder),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.panelBorder),
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
        color: palette.brand,
        linearTrackColor: palette.brandSoft,
        circularTrackColor: palette.brandSoft,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.brand,
        foregroundColor: palette.onBrand,
        elevation: 3,
        shape: const CircleBorder(),
      ),
    );
  }
}

/// A quiet fade and short lift for navigation. iOS keeps its interactive back
/// swipe. Reduced motion renders the destination without a visual transition.
class RiksaPageTransitionsBuilder extends PageTransitionsBuilder {
  const RiksaPageTransitionsBuilder({
    this.cupertino = false,
    this.predictiveBack = false,
  });
  final bool cupertino;
  final bool predictiveBack;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 240);
  @override
  Duration get reverseTransitionDuration => RiksaMotion.standard;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    if (predictiveBack) {
      return const PredictiveBackPageTransitionsBuilder().buildTransitions(
        route,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    if (cupertino) {
      return const CupertinoPageTransitionsBuilder().buildTransitions(
        route,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    final eased = animation.drive(CurveTween(curve: RiksaMotion.standardCurve));
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: eased.drive(
          Tween(begin: const Offset(0, .025), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}
