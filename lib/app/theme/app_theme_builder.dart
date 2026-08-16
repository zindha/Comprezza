import 'package:flutter/material.dart';

import '../../core/theme/app_brand_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_elevations.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import 'comprezza_theme.dart';

/// Composes application themes without feature dependencies.
///
/// Premium Material 3 tuned to the Comprezza identity: midnight navy canvases,
/// an electric-blue primary, and a rare cyan accent. The surface ladder is a
/// stepped navy-grey in dark mode so every surface reads at a different
/// elevation instead of collapsing into one dark blob. No purple anywhere.
abstract final class AppThemeBuilder {
  /// Builds the light Material 3 theme.
  static ThemeData light({
    bool highContrast = false,
    bool compact = false,
    bool large = false,
    bool colorBlindFriendly = false,
    bool largeTouchTargets = true,
  }) {
    return _base(
      _brandScheme(Brightness.light),
      highContrast: highContrast,
      compact: compact,
      large: large,
      colorBlindFriendly: colorBlindFriendly,
      largeTouchTargets: largeTouchTargets,
    );
  }

  /// Builds the dark Material 3 theme.
  static ThemeData dark({
    bool highContrast = false,
    bool compact = false,
    bool large = false,
    bool colorBlindFriendly = false,
    bool largeTouchTargets = true,
  }) {
    return _base(
      _brandScheme(Brightness.dark),
      highContrast: highContrast,
      compact: compact,
      large: large,
      colorBlindFriendly: colorBlindFriendly,
      largeTouchTargets: largeTouchTargets,
    );
  }

  /// The Comprezza semantic palette.
  ///
  /// Light mode anchors on electric blue for confident primary actions; dark
  /// mode uses the on-dark electric blue so actions stay legible on the navy
  /// canvas. Cyan is reserved for the savings/success accent. The surface
  /// ladder is navy-grey — the canvas the blue/cyan accents sit on.
  static ColorScheme _brandScheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const ColorScheme.dark(
        primary: Color(0xFF6EA8FF),
        onPrimary: Color(0xFF0B1B3A),
        primaryContainer: Color(0xFF1A2340),
        onPrimaryContainer: Color(0xFF6EA8FF),
        secondary: Color(0xFFA3B4D4),
        onSecondary: Color(0xFF1A2333),
        secondaryContainer: Color(0xFF2A3140),
        onSecondaryContainer: Color(0xFFD4DEEF),
        tertiary: Color(0xFF45E4F7),
        onTertiary: Color(0xFF00333A),
        tertiaryContainer: Color(0xFF0E3A40),
        onTertiaryContainer: Color(0xFF9BF0F8),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: Color(0xFF0B1226),
        onSurface: Color(0xFFF6F7FB),
        surfaceContainerLowest: Color(0xFF080D1C),
        surfaceContainerLow: Color(0xFF111A33),
        surfaceContainer: Color(0xFF1A2340),
        surfaceContainerHigh: Color(0xFF232D4D),
        surfaceContainerHighest: Color(0xFF2A3454),
        onSurfaceVariant: Color(0xFFA9B4C8),
        outline: Color(0xFF6B7690),
        outlineVariant: Color(0xFF2A3140),
        inverseSurface: Color(0xFFF6F7FB),
        onInverseSurface: Color(0xFF1A2130),
        inversePrimary: Color(0xFF2563EB),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
      );
    }
    return const ColorScheme.light(
      primary: Color(0xFF2563EB),
      primaryContainer: Color(0xFFD7E5FF),
      onPrimaryContainer: Color(0xFF00265C),
      secondary: Color(0xFF4A5C7A),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFE3E9F4),
      onSecondaryContainer: Color(0xFF182333),
      tertiary: Color(0xFF0E7490),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFCFF4FC),
      onTertiaryContainer: Color(0xFF0B3A46),
      error: Color(0xFFBA1A1A),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Color(0xFFF6F7FB),
      onSurface: Color(0xFF1A2130),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFFFFFFF),
      surfaceContainer: Color(0xFFF0F2F8),
      surfaceContainerHigh: Color(0xFFEAEDF4),
      surfaceContainerHighest: Color(0xFFE3E7F0),
      onSurfaceVariant: Color(0xFF465061),
      outline: Color(0xFF76808F),
      outlineVariant: Color(0xFFD8DEE8),
      inverseSurface: Color(0xFF2A3140),
      onInverseSurface: Color(0xFFF1F4FA),
      inversePrimary: Color(0xFF6EA8FF),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    );
  }

  static ThemeData _base(
    ColorScheme baseColors, {
    required bool highContrast,
    required bool compact,
    required bool large,
    required bool colorBlindFriendly,
    required bool largeTouchTargets,
  }) {
    final bool isDark = baseColors.brightness == Brightness.dark;
    final ColorScheme baseScheme = colorBlindFriendly
        ? _colorBlindFriendlyColors(baseColors)
        : baseColors;
    final ColorScheme colors = highContrast
        ? _highContrastColors(baseScheme)
        : baseScheme;
    final TextTheme textTheme = AppTypography.textTheme(colors.brightness)
        .apply(
          fontSizeFactor: large
              ? 1.12
              : compact
              ? .94
              : 1,
        );

    // Canvas: warm near-white in light, deep navy in dark. Cards then lift off
    // the canvas with soft shadow (light) or tonal elevation (dark).
    final Color scaffoldBackground = highContrast
        ? colors.surface
        : isDark
        ? const Color(0xFF0B1226)
        : const Color(0xFFF6F7FB);

    final Color cardColor = isDark
        ? colors.surfaceContainerHigh
        : Colors.white.withValues(alpha: .98);

    final BorderRadius cardRadius = BorderRadius.circular(AppRadius.large);
    final RoundedRectangleBorder cardShape = RoundedRectangleBorder(
      borderRadius: cardRadius,
      side: isDark
          ? BorderSide(color: colors.outlineVariant.withValues(alpha: .55))
          : BorderSide(color: colors.outlineVariant.withValues(alpha: .35)),
    );

    final BorderRadius controlRadius = BorderRadius.circular(AppRadius.small);

    final ComprezzaTheme comprezza = ComprezzaTheme(
      hairline: isDark
          ? colors.outlineVariant.withValues(alpha: .5)
          : colors.outlineVariant.withValues(alpha: .4),
      metricStyle: AppTypography.tabular(textTheme.headlineMedium!).copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w800,
        letterSpacing: -.4,
      ),
      metricSmallStyle: AppTypography.tabular(
        textTheme.titleMedium!,
      ).copyWith(color: colors.onSurface, fontWeight: FontWeight.w800),
      brandGradientStart: AppBrandColors.ink,
      brandGradientEnd: AppBrandColors.cyan,
      heroSurface: isDark
          ? colors.primaryContainer
          : colors.primaryContainer.withValues(alpha: .6),
    );

    // Shared button shape used by every button family.
    final ButtonStyle sharedButtonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size(0, AppDimensions.minInteractiveHeight),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingSm,
        ),
      ),
      shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: controlRadius),
      ),
      textStyle: const WidgetStatePropertyAll<TextStyle>(
        TextStyle(fontWeight: FontWeight.w700, letterSpacing: .1),
      ),
      animationDuration: const Duration(milliseconds: 140),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: colors,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[comprezza],
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      materialTapTargetSize: largeTouchTargets
          ? MaterialTapTargetSize.padded
          : MaterialTapTargetSize.shrinkWrap,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: -.2,
        ),
        iconTheme: IconThemeData(color: colors.onSurface),
        actionsIconTheme: IconThemeData(color: colors.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? AppElevations.none : AppElevations.subtle,
        margin: EdgeInsets.zero,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0 : .16),
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? colors.surfaceContainerHigh : cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: .2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
          height: 1.5,
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingLg,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? colors.surfaceContainerHigh : cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        modalBackgroundColor: isDark ? colors.surfaceContainerHigh : cardColor,
        showDragHandle: true,
        dragHandleColor: colors.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.extraLarge),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onInverseSurface,
        ),
        actionTextColor: colors.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        elevation: 3,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerHighest.withValues(
          alpha: isDark ? .65 : .5,
        ),
        selectedColor: colors.secondaryContainer,
        labelStyle: textTheme.labelLarge?.copyWith(color: colors.onSurface),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: colors.onSecondaryContainer,
        ),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .6)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        checkmarkColor: colors.onSecondaryContainer,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSm,
          vertical: AppDimensions.spacingXs,
        ),
        labelPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingXs,
        ),
        showCheckmark: true,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        textStyle: textTheme.labelMedium?.copyWith(
          color: colors.onInverseSurface,
        ),
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(milliseconds: 2000),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSm,
          vertical: AppDimensions.spacingXs,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? colors.surfaceContainerHigh : cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: .18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: colors.onSurface),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant.withValues(alpha: .5),
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceContainerHighest.withValues(alpha: .6),
        circularTrackColor: colors.surfaceContainerHighest.withValues(
          alpha: .6,
        ),
        linearMinHeight: 6,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.onSurfaceVariant,
        textColor: colors.onSurface,
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
          height: 1.4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingXs,
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: colors.onSurfaceVariant,
        collapsedIconColor: colors.onSurfaceVariant,
        textColor: colors.onSurface,
        collapsedTextColor: colors.onSurface,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        childrenPadding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: isDark
            ? const Color(0xFF111A33)
            : colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colors.secondaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (Set<WidgetState> states) => textTheme.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colors.onSurface
                : colors.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
          (Set<WidgetState> states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.onSecondaryContainer
                : colors.onSurfaceVariant,
          ),
        ),
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.pressed)
              ? colors.primary.withValues(alpha: .08)
              : null,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colors.secondaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: IconThemeData(color: colors.onSecondaryContainer),
        unselectedIconTheme: IconThemeData(color: colors.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: colors.onSurfaceVariant,
        ),
        groupAlignment: -1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        elevation: 2,
        highlightElevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingMd,
        ),
        extendedTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.onPrimaryContainer,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: .45),
        border: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: colors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: colors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: colors.error, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingMd,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant.withValues(alpha: .7),
        ),
        prefixIconColor: colors.onSurfaceVariant,
        suffixIconColor: colors.onSurfaceVariant,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 5,
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.surfaceContainerHighest,
        thumbColor: colors.primary,
        overlayColor: colors.primary.withValues(alpha: .12),
        thumbShape: const RoundSliderThumbShape(elevation: 3),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 23),
        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
        valueIndicatorColor: colors.primary,
        valueIndicatorTextStyle: textTheme.labelMedium?.copyWith(
          color: colors.onPrimary,
          fontWeight: FontWeight.w700,
        ),
        showValueIndicator: ShowValueIndicator.onlyForDiscrete,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.surfaceContainerHighest,
        ),
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected) ? colors.onPrimary : null,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : colors.outline.withValues(alpha: .5),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        side: BorderSide(color: colors.outline, width: 2),
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected) ? colors.primary : null,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: sharedButtonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: sharedButtonStyle.copyWith(
          elevation: const WidgetStatePropertyAll<double>(0),
          shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: sharedButtonStyle.copyWith(
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: colors.outlineVariant, width: 1.2),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: sharedButtonStyle.copyWith(
          minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 44)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
              vertical: AppDimensions.spacingSm,
            ),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
          ),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: colors.outlineVariant),
          ),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
          ),
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) => states.contains(WidgetState.pressed)
                ? colors.primary.withValues(alpha: .08)
                : null,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.onSurface,
        unselectedLabelColor: colors.onSurfaceVariant,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: colors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: colors.outlineVariant.withValues(alpha: .4),
        overlayColor: WidgetStatePropertyAll(
          colors.primary.withValues(alpha: .06),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ColorScheme _colorBlindFriendlyColors(ColorScheme colors) {
    // Rebuild the complete tonal role set instead of changing only primary,
    // secondary, and tertiary. This keeps every on*/container role paired
    // with the palette it belongs to at both brightnesses.
    final Color seed = colors.brightness == Brightness.light
        ? const Color(0xFF005AB5)
        : const Color(0xFF8EC7FF);
    return ColorScheme.fromSeed(seedColor: seed, brightness: colors.brightness);
  }

  static ColorScheme _highContrastColors(ColorScheme colors) => colors.copyWith(
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    surface: colors.brightness == Brightness.light
        ? Colors.white
        : Colors.black,
    onSurface: colors.brightness == Brightness.light
        ? Colors.black
        : Colors.white,
    outline: colors.brightness == Brightness.light
        ? Colors.black
        : Colors.white,
  );
}
