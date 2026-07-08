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
    secondary: Color(0xFF5B8DB8),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD7ECFF),
    onSecondaryContainer: Color(0xFF071E31),
    tertiary: Color(0xFF7E5700),
    onTertiary: Colors.white,
    error: RcPalette.danger,
    onError: Colors.white,
    surface: Color(0xFFFFF8FA), // 极淡粉白,页面底色
    onSurface: Color(0xFF201A1C),
    surfaceContainerHighest: Color(0xFFF3DCE3), // 卡片/分隔
    onSurfaceVariant: Color(0xFF524345),
    outline: Color(0xFF847375),
  );

  /// 暗色配色:粉调深灰背景 + 淡粉强调 + 淡蓝辅助色
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: RcPalette.pink200,
    onPrimary: Color(0xFF5E1133),
    primaryContainer: Color(0xFF7B2949),
    onPrimaryContainer: RcPalette.pink100,
    secondary: Color(0xFFA9CBE8),
    onSecondary: Color(0xFF10344C),
    secondaryContainer: Color(0xFF254A63),
    onSecondaryContainer: Color(0xFFD7ECFF),
    tertiary: Color(0xFFF2BE6D),
    onTertiary: Color(0xFF432C00),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: Color(0xFF1A1113), // 带暖粉调的深灰,非纯黑
    onSurface: Color(0xFFEBE0E1),
    surfaceContainerHighest: Color(0xFF524345),
    onSurfaceVariant: Color(0xFFD6C2C5),
    outline: Color(0xFF9E8C8F),
  );

  static ThemeData light = _build(_lightScheme, RcSemanticColors.light);
  static ThemeData dark = _build(_darkScheme, RcSemanticColors.dark);

  static ThemeData _build(ColorScheme scheme, RcSemanticColors semantic) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: <ThemeExtension<dynamic>>[semantic],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
