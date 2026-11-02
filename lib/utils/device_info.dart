import 'dart:io';

import 'package:flutter/services.dart';

/// @ClassName DeviceInfo
/// @Description 设备信息快照（机型、系统、CPU、内存等），用于「全局设置 - 设备信息」面板。
/// @Author richuff
/// @Version 1.0
class DeviceInfo {
  final String manufacturer;
  final String model;
  final String systemVersion;
  final int? sdkInt;
  final String cpuModel;
  final int cpuCores;
  final double? cpuMaxGhz;
  final int totalRamMb;
  final int availableRamMb;
  final String abi;
  final bool is64Bit;

  const DeviceInfo({
    required this.manufacturer,
    required this.model,
    required this.systemVersion,
    required this.sdkInt,
    required this.cpuModel,
    required this.cpuCores,
    required this.cpuMaxGhz,
    required this.totalRamMb,
    required this.availableRamMb,
    required this.abi,
    required this.is64Bit,
  });

  /// 例如 "Xiaomi 13" / "SM-G9910"
  String get deviceLabel {
    final brand = manufacturer.trim();
    final name = model.trim();
    if (brand.isEmpty && name.isEmpty) return '未知设备';
    if (name.isEmpty) return brand;
    if (brand.isEmpty) return name;
    if (name.toLowerCase().startsWith(brand.toLowerCase())) return name;
    return '$brand $name';
  }

  /// 例如 "Android 13 (API 33)"，桌面端回退为操作系统名称。
  String get systemLabel {
    final version = systemVersion.trim();
    if (sdkInt != null) {
      if (version.isEmpty) return 'Android (API $sdkInt)';
      return 'Android $version (API $sdkInt)';
    }
    final os = Platform.operatingSystem;
    final label = os[0].toUpperCase() + os.substring(1);
    if (version.isEmpty) return label;
    return '$label $version';
  }

  /// 例如 "8 核 · 最高 2.40 GHz · arm64-v8a"
  String get cpuLabel {
    final parts = <String>['$cpuCores 核'];
    if (cpuMaxGhz != null && cpuMaxGhz! > 0) {
      parts.add('最高 ${cpuMaxGhz!.toStringAsFixed(2)} GHz');
    }
    if (abi.isNotEmpty) parts.add(abi);
    if (is64Bit) parts.add('64 位');
    return parts.join(' · ');
  }

  String get ramLabel => '${formatMb(totalRamMb)} 总内存';

  String get ramUsageLabel {
    if (totalRamMb <= 0) return '未知';
    final used = (totalRamMb - availableRamMb).clamp(0, totalRamMb);
    return '已用 ${formatMb(used)} / 可用 ${formatMb(availableRamMb)}';
  }

  static String formatMb(int mb) {
    if (mb <= 0) return '未知';
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
    return '$mb MB';
  }
}

/// 读取设备信息。Android 通过原生通道获取机型/系统/内存，
/// CPU 型号与主频再通过 `/proc/cpuinfo`、`/sys/.../cpuinfo_max_freq` 补齐；
/// 其他平台回退到 `dart:io` 的 Platform 信息。
class DeviceInfoService {
  static const MethodChannel _channel = MethodChannel('rctool/device_info');

  static DeviceInfo? _cache;

  static Future<DeviceInfo> load({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;

    Map<String, dynamic> native = <String, dynamic>{};
    if (Platform.isAndroid) {
      try {
        native = await _channel.invokeMapMethod<String, dynamic>(
              'getDeviceInfo',
            ) ??
            <String, dynamic>{};
      } on PlatformException {
        native = <String, dynamic>{};
      } on MissingPluginException {
        native = <String, dynamic>{};
      }
    }

    final cpuInfo = _readCpuInfo();
    final totalRam = _asMb(native['totalRam']) ?? _readMemTotalMb() ?? 0;
    final availRam = _asMb(native['availRam']) ?? 0;

    final info = DeviceInfo(
      manufacturer: (native['manufacturer'] as String?) ??
          (Platform.isAndroid ? '' : Platform.localHostname),
      model: (native['model'] as String?) ?? '',
      systemVersion: (native['androidVersion'] as String?) ??
          Platform.operatingSystemVersion,
      sdkInt: (native['sdkInt'] as num?)?.toInt(),
      cpuModel: cpuInfo.model,
      cpuCores: (native['cpuCores'] as num?)?.toInt() ??
          Platform.numberOfProcessors,
      cpuMaxGhz: _readCpuMaxGhz(),
      totalRamMb: totalRam,
      availableRamMb: availRam,
      abi: (native['cpuAbi'] as String?) ?? _abiFromPlatform(),
      is64Bit: (native['is64Bit'] as bool?) ?? _runtimeIs64Bit(),
    );

    _cache = info;
    return info;
  }

  /// Android 的内存值单位是字节，统一换算为 MB。
  static int? _asMb(dynamic bytes) {
    if (bytes is num && bytes > 0) {
      return (bytes / (1024 * 1024)).round();
    }
    return null;
  }

  static String _abiFromPlatform() {
    if (!Platform.isAndroid && !Platform.isLinux) return '';
    try {
      final result = Process.runSync('uname', ['-m']);
      final arch = (result.stdout as String).trim();
      return arch;
    } catch (_) {
      return '';
    }
  }

  /// 通过 Dart VM 版本串判断运行时架构是否为 64 位。
  static bool _runtimeIs64Bit() {
    final version = Platform.version.toLowerCase();
    if (version.contains('x64') || version.contains('arm64')) return true;
    if (version.contains('ia32') || version.contains('arm')) return false;
    return _abiFromPlatform().contains('64');
  }

  /// 解析 `/proc/cpuinfo` 中的硬件型号。
  static _CpuInfo _readCpuInfo() {
    const keys = ['Hardware', 'model name', 'Processor', 'chipset'];
    try {
      final file = File('/proc/cpuinfo');
      if (!file.existsSync()) return const _CpuInfo('');
      final lines = file.readAsLinesSync();
      for (final key in keys) {
        for (final line in lines) {
          final separator = line.indexOf(':');
          if (separator <= 0) continue;
          final name = line.substring(0, separator).trim();
          if (name.toLowerCase() != key.toLowerCase()) continue;
          final value = line.substring(separator + 1).trim();
          if (value.isEmpty) continue;
          return _CpuInfo(_cleanCpuName(value));
        }
      }
    } catch (_) {
      // 读取失败时保持空值，不影响其他信息展示。
    }
    return const _CpuInfo('');
  }

  static String _cleanCpuName(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\(R\)|\(TM\)|CPU|Processor', caseSensitive: false), '')
        .trim();
  }

  /// 读取 CPU 最高主频（kHz → GHz）。
  static double? _readCpuMaxGhz() {
    try {
      final cores = Platform.numberOfProcessors;
      int? maxKhz;
      for (var index = 0; index < cores; index++) {
        final file = File(
          '/sys/devices/system/cpu/cpu$index/cpufreq/cpuinfo_max_freq',
        );
        if (!file.existsSync()) continue;
        final value = int.tryParse(file.readAsStringSync().trim());
        if (value == null || value <= 0) continue;
        if (maxKhz == null || value > maxKhz) maxKhz = value;
      }
      if (maxKhz == null) return null;
      return maxKhz / 1000000;
    } catch (_) {
      return null;
    }
  }

  /// 兜底：从 `/proc/meminfo` 读取总内存。
  static int? _readMemTotalMb() {
    try {
      final file = File('/proc/meminfo');
      if (!file.existsSync()) return null;
      for (final line in file.readAsLinesSync()) {
        if (!line.startsWith('MemTotal:')) continue;
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length < 2) return null;
        final kb = int.tryParse(parts[1]);
        if (kb == null) return null;
        return (kb / 1024).round();
      }
    } catch (_) {
      // ignore
    }
    return null;
  }
}

class _CpuInfo {
  final String model;
  const _CpuInfo(this.model);
}
