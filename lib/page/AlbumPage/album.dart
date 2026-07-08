import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/repository/SqlLiteConn/music_conn.dart';
import 'package:rctool/repository/SqlLiteConn/playlist_conn.dart';
import 'package:rctool/repository/entity/Music.dart';
import 'package:rctool/repository/entity/playlist.dart';
import 'package:rctool/widget/BackGround/back_ground_enum.dart';

import '../../feature/design/icon_button_no_ripple.dart';
import '../../widget/main_drawer.dart';
import '../../widget/search_widget.dart';

class Album extends StatefulWidget {
  const Album({super.key});

  @override
  State<Album> createState() => _Album();
}

class _Album extends State<Album> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _nameController = TextEditingController();
  final MusicController musicController =
      Get.put(MusicController(), permanent: true);

  List<Playlist> playlists = [];
  List<Music> selectedMusic = [];
  List<Music> allMusic = [];
  Playlist? selectedPlaylist;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    playlists = await PlaylistConn.queryPlaylists();
    allMusic = await MusicConn.queryAll();
    selectedPlaylist ??= playlists.isNotEmpty ? playlists.first : null;
    if (selectedPlaylist != null) {
      selectedMusic =
          await PlaylistConn.queryMusicByPlaylist(selectedPlaylist!.id!);
    } else {
      selectedMusic = [];
    }
    if (mounted) setState(() {});
  }

  Future<void> _selectPlaylist(Playlist playlist) async {
    selectedPlaylist = playlist;
    selectedMusic = await PlaylistConn.queryMusicByPlaylist(playlist.id!);
    if (mounted) setState(() {});
  }

  Future<void> _createPlaylist() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await PlaylistConn.insertPlaylist(name);
    _nameController.clear();
    await _loadData();
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    await PlaylistConn.deletePlaylist(playlist.id!);
    if (selectedPlaylist?.id == playlist.id) {
      selectedPlaylist = null;
      selectedMusic = [];
    }
    await _loadData();
  }

  Future<void> _showAddMusicDialog() async {
    if (selectedPlaylist == null) return;
    await showDialog(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text("添加歌曲"),
          content: SizedBox(
            width: 420,
            height: 420,
            child: allMusic.isEmpty
                ? const Center(child: Text("暂无可添加歌曲"))
                : ListView.builder(
                    itemCount: allMusic.length,
                    itemBuilder: (context, index) {
                      final music = allMusic[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            music.imageUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 44,
                              height: 44,
                              color: scheme.surfaceVariant,
                              child: Icon(
                                Icons.music_note,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        title: Text(music.songName),
                        subtitle: Text(music.decoration),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () async {
                            await PlaylistConn.addMusic(
                              selectedPlaylist!.id!,
                              music.id!,
                            );
                            await _selectPlaylist(selectedPlaylist!);
                            if (context.mounted) Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      key: scaffoldKey,
      drawerScrimColor: Colors.transparent,
      drawer: MainDrawer(() {
        scaffoldKey.currentState?.closeDrawer();
      }),
      appBar: AppBar(
          backgroundColor: scheme.surface,
          leading: Builder(builder: (context) {
            return Column(children: [
              const Padding(padding: EdgeInsets.only(top: 8)),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: IconButtonNoRipple(
                  hoverColor: scheme.primaryContainer,
                  focusColor: scheme.primaryContainer,
                  highlightColor: scheme.secondaryContainer,
                  alignment: Alignment.bottomCenter,
                  icon: const Icon(
                    Icons.menu,
                    size: 26,
                  ),
                  color: scheme.onSurface,
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ]);
          }),
          actions: const [SearchWidget()]),
      body: Container(
          width: double.infinity,
          decoration: BackGroundEnum.musicBackGround.decoration,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(scrollbars: false, dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            }),
            child: LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              final content = [
                _PlaylistPanel(
                  playlists: playlists,
                  selectedPlaylist: selectedPlaylist,
                  nameController: _nameController,
                  onCreate: _createPlaylist,
                  onSelect: _selectPlaylist,
                  onDelete: _deletePlaylist,
                ),
                _PlaylistDetail(
                  playlist: selectedPlaylist,
                  musicList: selectedMusic,
                  onAddMusic: _showAddMusicDialog,
                  onPlayAll: () =>
                      musicController.addMusicListToQueue(selectedMusic),
                  onRemoveMusic: (music) async {
                    await PlaylistConn.removeMusic(
                      selectedPlaylist!.id!,
                      music.id!,
                    );
                    await _selectPlaylist(selectedPlaylist!);
                  },
                  onPlayMusic: (music) {
                    musicController.playOrPauseMusic(
                      music,
                      list: selectedMusic,
                      startIndex: selectedMusic.indexOf(music),
                    );
                  },
                  isPlayingMusic: musicController.isPlayingMusic,
                ),
              ];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 300, child: content[0]),
                          const SizedBox(width: 16),
                          Expanded(child: content[1]),
                        ],
                      )
                    : Column(
                        children: [
                          content[0],
                          const SizedBox(height: 16),
                          content[1],
                        ],
                      ),
              );
            }),
          )),
    );
  }
}

class _PlaylistPanel extends StatelessWidget {
  final List<Playlist> playlists;
  final Playlist? selectedPlaylist;
  final TextEditingController nameController;
  final Future<void> Function() onCreate;
  final Future<void> Function(Playlist playlist) onSelect;
  final Future<void> Function(Playlist playlist) onDelete;

  const _PlaylistPanel({
    required this.playlists,
    required this.selectedPlaylist,
    required this.nameController,
    required this.onCreate,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "歌单".tr,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: "新歌单名称",
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: "创建歌单",
                onPressed: onCreate,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "还没有歌单",
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...playlists.map((playlist) {
              final selected = selectedPlaylist?.id == playlist.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primaryContainer
                      : scheme.surfaceVariant.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  selected: selected,
                  title: Text(playlist.name),
                  subtitle: Text("${playlist.musicCount} 首歌曲"),
                  trailing: IconButton(
                    tooltip: "删除歌单",
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => onDelete(playlist),
                  ),
                  onTap: () => onSelect(playlist),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _PlaylistDetail extends StatelessWidget {
  final Playlist? playlist;
  final List<Music> musicList;
  final VoidCallback onAddMusic;
  final VoidCallback onPlayAll;
  final Future<void> Function(Music music) onRemoveMusic;
  final void Function(Music music) onPlayMusic;
  final bool Function(Music music) isPlayingMusic;

  const _PlaylistDetail({
    required this.playlist,
    required this.musicList,
    required this.onAddMusic,
    required this.onPlayAll,
    required this.onRemoveMusic,
    required this.onPlayMusic,
    required this.isPlayingMusic,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  playlist?.name ?? "请选择歌单",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "${musicList.length} 首",
                  style: TextStyle(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: "添加歌曲",
                onPressed: playlist == null ? null : onAddMusic,
                icon: const Icon(Icons.library_add),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: musicList.isEmpty ? null : onPlayAll,
                icon: const Icon(Icons.play_arrow),
                label: const Text("播放"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (playlist == null)
            SizedBox(
              height: 240,
              child: Center(
                child: Text(
                  "创建或选择一个歌单",
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          else if (musicList.isEmpty)
            SizedBox(
              height: 240,
              child: Center(
                child: Text(
                  "这个歌单还没有歌曲",
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...musicList.map((music) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      music.imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: scheme.primaryContainer,
                        child: Icon(
                          Icons.music_note,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  title: Text(music.songName),
                  subtitle: Text(music.decoration),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: "播放歌曲",
                        onPressed: () => onPlayMusic(music),
                        icon: GetBuilder<MusicController>(
                          builder: (_) {
                            final playing = isPlayingMusic(music);
                            return Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                              color: playing ? scheme.primary : null,
                            );
                          },
                        ),
                      ),
                      IconButton(
                        tooltip: "移出歌单",
                        icon: const Icon(Icons.close),
                        onPressed: () => onRemoveMusic(music),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
