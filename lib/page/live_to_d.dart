import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/feature/theme/type_value.dart';
import 'package:rctool/service/live2d_model_library.dart';
import 'package:rctool/widget/BackGround/back_ground_enum.dart';
import 'package:rctool/widget/app_scaffold.dart';
import 'package:rctool/widget/live2d/live2d_model_sheet.dart';
import 'package:rctool/widget/live2d/live2d_webview.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// @ClassName LiveTod
/// @Description Live2D 页：WebView 全屏展示模型，叠加模型信息、缩放条、互动提示与重新加载入口。
/// @Author richuff
/// @Version 2.1
class LiveTod extends StatefulWidget {
  const LiveTod({super.key});

  @override
  State<LiveTod> createState() => _LiveTodState();
}

class _LiveTodState extends State<LiveTod> {
  /// 默认缩放：整屏贴合会显得过大，留出边距看起来更自然
  static const double _defaultZoom = 0.8;
  static const double _minZoom = 0.45;
  static const double _maxZoom = 1.6;

  /// 改变该值即可重建 WebView，实现「重新加载」。
  int _reloadToken = 0;
  bool _showTips = true;
  double _zoom = _defaultZoom;

  final MusicController _musicController = Get.find<MusicController>();

  /// 口型联动开关（默认开），只在播放时真正驱动嘴部
  bool _lipSync = true;
  bool _wasPlaying = false;

  /// 当前模型（内置 Haru 兜底）
  Live2DModelEntry _model = Live2DModelLibrary.builtIn;

  @override
  void initState() {
    super.initState();
    _loadZoom();
    _loadLipSync();
    _loadModelSelection();
    _wasPlaying = _musicController.isplay.value;
    _musicController.addListener(_onMusicChanged);
  }

  @override
  void dispose() {
    _musicController.removeListener(_onMusicChanged);
    super.dispose();
  }

  /// 只关心「播放 / 暂停」的切换，避免每秒几十次进度回调触发重建
  void _onMusicChanged() {
    final playing = _musicController.isplay.value;
    if (playing == _wasPlaying) return;
    _wasPlaying = playing;
    if (mounted) setState(() {});
  }

  Future<void> _loadLipSync() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(live2dLipSyncKey);
    if (!mounted || saved == null) return;
    setState(() => _lipSync = saved);
  }

  Future<void> _toggleLipSync() async {
    setState(() => _lipSync = !_lipSync);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(live2dLipSyncKey, _lipSync);
  }

  Future<void> _loadZoom() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(live2dZoomKey);
    if (!mounted || saved == null) return;
    setState(() {
      _zoom = saved.clamp(_minZoom, _maxZoom).toDouble();
    });
  }

  /// 扫描外部模型目录（选择面板与页面共用同一份扫描逻辑）
  Future<List<Live2DModelEntry>> _scanModels() async {
    return Live2DModelLibrary.scan();
  }

  /// 读取上次选中的模型；模型被删掉时自动回到内置 Haru
  Future<void> _loadModelSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(live2dModelKey);
    if (!mounted) return;
    // 先用持久化的 id 直接还原，避免第一帧加载内置模型后再切换
    if (savedId != null && savedId != _model.id) {
      setState(() => _model = Live2DModelLibrary.entryFromId(savedId));
    }
    final models = await _scanModels();
    if (!mounted) return;
    final resolved = Live2DModelLibrary.resolve(models, savedId);
    if (resolved.id != _model.id) {
      setState(() => _model = resolved);
    }
  }

  Future<void> _pickModel() async {
    final picked = await showModalBottomSheet<Live2DModelEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Live2DModelSheet(
        selectedId: _model.id,
        onScan: _scanModels,
      ),
    );
    if (picked == null || !mounted || picked.id == _model.id) return;
    setState(() {
      _model = picked;
      _reloadToken++;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(live2dModelKey, picked.id);
  }

  Future<void> _saveZoom() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(live2dZoomKey, _zoom);
  }

  void _setZoom(double value) {
    final next = value.clamp(_minZoom, _maxZoom).toDouble();
    if (next == _zoom) return;
    setState(() => _zoom = next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppScaffold(
      background: BackGroundEnum.livetodBackGround,
      body: Stack(
        children: [
          Positioned.fill(
            child: Live2DWebView(
              key: ValueKey('live2d-${_model.id}-$_reloadToken'),
              assetPath: 'assets/live2d/viewer/index.html',
              modelUrl: _model.modelPath,
              zoom: _zoom,
              lipSync: _lipSync && _wasPlaying,
            ),
          ),
          // 顶部渐隐，让 WebView 与应用栏自然衔接
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 56,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.surface.withOpacity(0.9),
                      scheme.surface.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 模型徽标：点击打开模型选择（自动扫描外部目录）
          Positioned(
            left: 16,
            top: 14,
            child: _modelChip(scheme),
          ),
          // 口型联动开关
          Positioned(
            right: 16,
            top: 14,
            child: _lipSyncChip(scheme),
          ),
          // 底部：互动提示 + 缩放条
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.bottomCenter,
                  child: _showTips
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _tipsCard(scheme),
                            const SizedBox(height: 10),
                          ],
                        )
                      : Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _tipsButton(scheme),
                          ),
                        ),
                ),
                _zoomBar(scheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 模型徽标：显示当前模型名，点开可切换（模型数量 > 1 时加下拉箭头）
  Widget _modelChip(ColorScheme scheme) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _pickModel,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outline.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.face_retouching_natural,
                  size: 14, color: scheme.primary),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 116),
                child: Text(
                  _model.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded,
                  size: 14, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  /// 口型联动开关：开启且正在播放时，嘴型会跟着音乐开合
  Widget _lipSyncChip(ColorScheme scheme) {
    final active = _lipSync && _wasPlaying;
    final color = _lipSync ? scheme.primary : scheme.onSurfaceVariant;
    return Tooltip(
      message: _lipSync
          ? '播放音乐时 Haru 会跟着一起唱，点此关闭'.tr
          : '点此开启口型联动'.tr,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _toggleLipSync,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(_lipSync ? 0.9 : 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _lipSync
                    ? scheme.primary.withOpacity(0.42)
                    : scheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? Icons.graphic_eq_rounded : Icons.voice_over_off,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 5),
                Text(
                  '口型联动'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (active) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tipsCard(ColorScheme scheme) {    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outline.withOpacity(0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.touch_app_outlined,
                    size: 20, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '互动提示'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '拖动模型身体可以切换动作，视线会跟随指针'.tr,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '重新加载'.tr,
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() {
                    _reloadToken++;
                    _showTips = true;
                  });
                },
                icon: Icon(Icons.refresh_rounded,
                    color: scheme.onSurfaceVariant),
              ),
              IconButton(
                tooltip: '收起提示'.tr,
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _showTips = false),
                icon: Icon(Icons.close_rounded,
                    size: 20, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipsButton(ColorScheme scheme) {
    return Material(
      color: scheme.surface.withOpacity(0.9),
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: scheme.shadow,
      child: IconButton(
        tooltip: '互动提示'.tr,
        visualDensity: VisualDensity.compact,
        onPressed: () => setState(() => _showTips = true),
        icon: Icon(Icons.help_outline_rounded, color: scheme.primary),
      ),
    );
  }

  /// 缩放条：− / 滑块 / ＋，右侧显示百分比（点击恢复默认大小）
  Widget _zoomBar(ColorScheme scheme) {
    final percent = (_zoom * 100).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 46,
          padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.82),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              _zoomIconButton(
                scheme,
                icon: Icons.remove_rounded,
                tooltip: '缩小'.tr,
                onPressed: () {
                  _setZoom(_zoom - 0.1);
                  _saveZoom();
                },
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: scheme.primary,
                    inactiveTrackColor: scheme.surfaceContainerHighest,
                    thumbColor: scheme.primary,
                    overlayColor: scheme.primary.withOpacity(0.12),
                  ),
                  child: Slider(
                    value: _zoom.clamp(_minZoom, _maxZoom).toDouble(),
                    min: _minZoom,
                    max: _maxZoom,
                    onChanged: _setZoom,
                    onChangeEnd: (_) => _saveZoom(),
                  ),
                ),
              ),
              _zoomIconButton(
                scheme,
                icon: Icons.add_rounded,
                tooltip: '放大'.tr,
                onPressed: () {
                  _setZoom(_zoom + 0.1);
                  _saveZoom();
                },
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: '恢复到默认大小'.tr,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    _setZoom(_defaultZoom);
                    _saveZoom();
                  },
                  child: Container(
                    width: 46,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _zoomIconButton(
    ColorScheme scheme, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 19, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
