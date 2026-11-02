import 'package:flutter/material.dart';

/// @ClassName RcPalette
/// @Description 集中管理的调色板 —— 主色为淡粉色(玫瑰粉)。
///   颜色以「语义角色」而非具体色值被引用,方便切换亮/暗模式与后续换肤。
///   60-30-10:大面积用中性 surface,30% 次要色,10% primary 强调。
/// @Author richuff
/// @Date 2026-07-06
/// @Version 1.0
class RcPalette {
  RcPalette._();

  /// 淡粉色阶(从浅到深),供 UI 直接取用
  static const Color pink50 = Color(0xFFFFF0F5);
  static const Color pink100 = Color(0xFFFFD9E4);
  static const Color pink200 = Color(0xFFFFB0C9);
  static const Color pink300 = Color(0xFFF48FB1);
  static const Color pink400 = Color(0xFFE86D9A);
  static const Color pink500 = Color(0xFFC8567F); // 主色:承载白字仍达 AA
  static const Color pink600 = Color(0xFFA83E66);

  /// 语义状态色(亮色)
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color info = Color(0xFF1565C0);
  static const Color danger = Color(0xFFBA1A1A);
}

/// @ClassName RcSemanticColors
/// @Description 随亮/暗模式变化的语义色扩展。
///   ColorScheme 不含 success/warning/info,用 ThemeExtension 补齐,
///   使用处:`Theme.of(context).extension<RcSemanticColors>()!.success`
/// @Author richuff
/// @Date 2026-07-06
/// @Version 1.0
@immutable
class RcSemanticColors extends ThemeExtension<RcSemanticColors> {
  final Color success;
  final Color warning;
  final Color info;

  const RcSemanticColors({
    required this.success,
    required this.warning,
    required this.info,
  });

  static const light = RcSemanticColors(
    success: RcPalette.success,
    warning: RcPalette.warning,
    info: RcPalette.info,
  );

  static const dark = RcSemanticColors(
    success: Color(0xFF81C784),
    warning: Color(0xFFFFD54F),
    info: Color(0xFF90CAF9),
  );

  @override
  RcSemanticColors copyWith({Color? success, Color? warning, Color? info}) {
    return RcSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  RcSemanticColors lerp(ThemeExtension<RcSemanticColors>? other, double t) {
    if (other is! RcSemanticColors) return this;
    return RcSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

/// @ClassName AppTheme
/// @Description 亮色 / 暗色两套 ThemeData,主色为淡粉色。
///   在 GetMaterialApp 中配合 themeMode 使用。
/// @Author richuff
/// @Date 2026-07-06
/// @Version 1.0
class AppTheme {
  AppTheme._();

  /// 亮色配色:淡粉背景 + 玫瑰粉强调 + 淡蓝辅助色
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: RcPalette.pink500,
    onPrimary: Colors.white,
    primaryContainer: RcPalette.pink100,
    onPrimaryContainer: Color(0xFF3E0021),
    secondary: Color(0xFF526F86),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD5E0E8),
    onSecondaryContainer: Color(0xFF071E31),
    tertiary: Color(0xFF7E5700),
    onTertiary: Colors.white,
    error: RcPalette.danger,
    onError: Colors.white,
    surface: Color(0xFFFFF8FA), // 极淡粉白,页面底色
    onSurface: Color(0xFF201A1C),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFF1F5),
    surfaceContainer: Color(0xFFFCE9EF),
    surfaceContainerHigh: Color(0xFFF7E1E8),
    surfaceContainerHighest: Color(0xFFF2D8E1), // 卡片/分隔
    onSurfaceVariant: Color(0xFF524345),
    outline: Color(0xFF847375),
    outlineVariant: Color(0xFFDCC7CC),
    shadow: Color(0xFF2A1218),
    scrim: Color(0xFF2A1218),
  );

  /// 暗色配色:粉调深灰背景 + 低饱和玫瑰粉强调 + 淡蓝辅助色。
  ///   注意：暗色下主色刻意压暗（原来的浅粉色会让 FilledButton / 图标按钮
  ///   在深色背景上亮得刺眼），容器色也整体下沉一档。
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFD98BA8),
    onPrimary: Color(0xFF3A0A1E),
    primaryContainer: Color(0xFF5C2A3D),
    onPrimaryContainer: Color(0xFFF7D9E3),
    secondary: Color(0xFF9CBCCB),
    onSecondary: Color(0xFF0E2B3C),
    secondaryContainer: Color(0xFF27404E),
    onSecondaryContainer: Color(0xFFD6E5EC),
    tertiary: Color(0xFFD9B174),
    onTertiary: Color(0xFF3A2A00),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: Color(0xFF1A1113), // 带暖粉调的深灰,非纯黑
    onSurface: Color(0xFFEBE0E1),
    surfaceContainerLowest: Color(0xFF120C0E),
    surfaceContainerLow: Color(0xFF201618),
    surfaceContainer: Color(0xFF251A1D),
    surfaceContainerHigh: Color(0xFF2F2226),
    surfaceContainerHighest: Color(0xFF3A2C30), // 卡片/分隔
    onSurfaceVariant: Color(0xFFCBB6BA),
    outline: Color(0xFF8A7679),
    outlineVariant: Color(0xFF463539),
    shadow: Colors.black,
    scrim: Colors.black,
  );

  static ThemeData light = _build(_lightScheme, RcSemanticColors.light);
  static ThemeData dark = _build(_darkScheme, RcSemanticColors.dark);

  static ThemeData _build(ColorScheme scheme, RcSemanticColors semantic) {
    final isDark = scheme.brightness == Brightness.dark;
    final radius12 = BorderRadius.circular(12);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[semantic],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      // 统一的按钮观感：暗色下只比底色亮一档，不再出现刺眼的高亮块
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
          disabledBackgroundColor: scheme.surfaceContainerHigh,
          disabledForegroundColor: scheme.onSurfaceVariant,
          elevation: isDark ? 0 : 2,
          shadowColor: scheme.shadow,
          shape: RoundedRectangleBorder(borderRadius: radius12),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.surfaceContainerHigh,
          disabledForegroundColor: scheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: radius12),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: radius12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
      ),
      cardTheme: CardTheme(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 3,
        shadowColor: scheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius12),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        actionTextColor: scheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius12),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withOpacity(0.7),
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHigh,
        circularTrackColor: scheme.surfaceContainerHigh,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHigh,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withOpacity(0.14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return scheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface, fontSize: 12),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.6)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: scheme.onSurface, fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
      ),
    );
  }
}
