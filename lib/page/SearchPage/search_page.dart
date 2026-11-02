import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/feature/theme/type_value.dart';
import 'package:rctool/repository/SqlLiteConn/music_conn.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/widget/BackGround/back_ground_enum.dart';
import 'package:rctool/widget/play_all_button.dart';
import 'package:rctool/widget/song_actions_sheet.dart';
import 'package:rctool/widget/song_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// @ClassName SearchPage
/// @Description 曲库搜索：按歌名 / 歌手实时过滤本地曲库，命中关键词高亮，
///              记录最近搜索，支持整组播放与单曲「…」操作。
/// @Author richuff
/// @Version 1.0
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final MusicController musicController = Get.find<MusicController>();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Music> _all = [];
  List<Music> _results = [];
  List<String> _history = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = await MusicConn.queryAll();
    if (!mounted) return;
    setState(() {
      _all = list;
      _history = prefs.getStringList(searchHistoryKey) ?? [];
      _loading = false;
      _results = list;
    });
    // 进入页面自动聚焦，省掉一次点击
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      _results = _filter(value);
    });
  }

  List<Music> _filter(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return _all;
    return _all
        .where((music) =>
            music.songName.toLowerCase().contains(query) ||
            music.decoration.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _rememberQuery(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;
    final next =
        [query, ..._history.where((item) => item != query)].take(10).toList();
    setState(() => _history = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(searchHistoryKey, next);
  }

  Future<void> _clearHistory() async {
    setState(() => _history = []);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(searchHistoryKey);
  }

  void _useHistory(String value) {
    _textController.text = value;
    _textController.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));
    _onQueryChanged(value);
    _rememberQuery(value);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasQuery = _query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: '返回'.tr,
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _textController,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          onChanged: _onQueryChanged,
          onSubmitted: (value) {
            _rememberQuery(value);
            _onQueryChanged(value);
          },
          style: TextStyle(fontSize: 15, color: scheme.onSurface),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withOpacity(0.5),
            hintText: '搜索歌名或歌手'.tr,
            hintStyle: TextStyle(
              fontSize: 14,
              color: scheme.onSurfaceVariant.withOpacity(0.7),
            ),
            prefixIcon: Icon(Icons.search_rounded,
                size: 20, color: scheme.onSurfaceVariant),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          if (hasQuery)
            IconButton(
              tooltip: '清除'.tr,
              onPressed: () {
                _textController.clear();
                _onQueryChanged('');
                _focusNode.requestFocus();
              },
              icon: Icon(Icons.close_rounded,
                  size: 20, color: scheme.onSurfaceVariant),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: BackGroundEnum.musicBackGround.decoration,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (Theme.of(context).brightness == Brightness.dark)
                IgnorePointer(
                  child: ColoredBox(color: scheme.surface.withOpacity(0.62)),
                ),
              _body(scheme, hasQuery),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(ColorScheme scheme, bool hasQuery) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (!hasQuery && _history.isNotEmpty) _historySection(scheme),
        if (!hasQuery) _allSongsHeader(scheme),
        if (hasQuery) _resultHeader(scheme),
        if (_results.isEmpty)
          _emptyState(scheme, hasQuery)
        else
          ..._results.asMap().entries.map((entry) {
            final music = entry.value;
            return SongRow(
              music: music,
              highlight: hasQuery ? _query.trim() : null,
              playing: musicController.isPlayingMusic(music),
              loading: musicController.loadingUrl.value.isNotEmpty &&
                  musicController.loadingUrl.value == music.url,
              onPlayToggle: () {
                _rememberQuery(_query);
                musicController.playMusicList(
                  _results,
                  startIndex: entry.key,
                );
              },
              onMore: () => showSongActions(context, music),
            );
          }),
      ],
    );
  }

  Widget _historySection(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 15, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                '最近搜索'.tr,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearHistory,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  '清空'.tr,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in _history)
                ActionChip(
                  label: Text(item, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _useHistory(item),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: scheme.outlineVariant.withOpacity(0.4),
                  ),
                  backgroundColor: scheme.surface.withOpacity(0.7),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _allSongsHeader(ColorScheme scheme) {
    return _sectionHeader(
      scheme,
      icon: Icons.library_music_rounded,
      title: '全部歌曲'.tr,
      trailing: '共 @count 首'.trParams({'count': '${_all.length}'}),
    );
  }

  Widget _resultHeader(ColorScheme scheme) {
    return _sectionHeader(
      scheme,
      icon: Icons.search_rounded,
      title: '找到 @count 首'.trParams({'count': '${_results.length}'}),
      action: _results.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 6),
              child: PlayAllButton(
                dense: true,
                onPressed: () {
                  _rememberQuery(_query);
                  musicController.playMusicList(_results, startIndex: 0);
                },
              ),
            ),
    );
  }

  Widget _sectionHeader(
    ColorScheme scheme, {
    required IconData icon,
    required String title,
    String? trailing,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing,
              style: TextStyle(
                fontSize: 11.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _emptyState(ColorScheme scheme, bool hasQuery) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withOpacity(0.55),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasQuery
                  ? Icons.search_off_rounded
                  : Icons.library_music_outlined,
              size: 30,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasQuery ? '没有找到匹配的歌曲'.tr : '曲库里还没有歌曲'.tr,
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
