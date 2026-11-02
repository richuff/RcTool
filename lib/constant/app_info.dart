/// 应用基础信息常量。
class AppInfo {
  AppInfo._();

  static const String name = 'RcTool';
  static const String version = '1.0.0+1';

  /// 去掉 build 号后的展示版本号（v1.0.0）
  static String get displayVersion => 'v${version.split('+').first}';
  static const String repoUrl = 'https://github.com/richuff/RcTool';
  static const String author = 'richuff';
}
