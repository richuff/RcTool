import 'package:get/get.dart';

import '../repository/SqlLiteConn/favorite_conn.dart';
import '../repository/SqlLiteConn/playlist_conn.dart';
import '../repository/entity/Music.dart';
import '../repository/entity/playlist.dart';

class FavoriteController extends GetxController {
  final Set<int> _favoriteMusicIds = <int>{};
  final Set<int> _favoritePlaylistIds = <int>{};
  List<Music> favoriteMusic = <Music>[];
  List<Playlist> favoritePlaylists = <Playlist>[];
  bool _loaded = false;

  @override
  void onInit() {
    super.onInit();
    ensureLoaded();
  }

  bool isFavorite(int? musicId) {
    return musicId != null && _favoriteMusicIds.contains(musicId);
  }

  bool isFavoritePlaylist(int? playlistId) {
    return playlistId != null && _favoritePlaylistIds.contains(playlistId);
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await refresh();
  }

  @override
  Future<void> refresh() async {
    favoriteMusic = await FavoriteConn.queryFavoriteMusic();
    favoritePlaylists = await PlaylistConn.queryFavoritePlaylists();
    _favoriteMusicIds
      ..clear()
      ..addAll(
          favoriteMusic.where((music) => music.id != null).map((music) => music.id!));
    _favoritePlaylistIds
      ..clear()
      ..addAll(favoritePlaylists
          .where((playlist) => playlist.id != null)
          .map((playlist) => playlist.id!));
    _loaded = true;
    update();
  }

  Future<void> toggle(int? musicId) async {
    if (musicId == null) return;
    final wasFavorite = isFavorite(musicId);

    // 先改内存并通知界面：等数据库写完再刷新会有可感知的延迟，
    // 播放页的爱心因此要过一会儿才变红。失败时回滚。
    if (wasFavorite) {
      _favoriteMusicIds.remove(musicId);
    } else {
      _favoriteMusicIds.add(musicId);
    }
    update();

    try {
      if (wasFavorite) {
        await FavoriteConn.deleteByMusicId(musicId);
      } else {
        await FavoriteConn.insertFavoriteMusic(musicId);
      }
    } catch (error) {
      if (wasFavorite) {
        _favoriteMusicIds.add(musicId);
      } else {
        _favoriteMusicIds.remove(musicId);
      }
      update();
      rethrow;
    }

    await refresh();
  }

  Future<void> add(int? musicId) async {
    if (musicId == null) return;
    await FavoriteConn.insertFavoriteMusic(musicId);
    await refresh();
  }

  Future<void> addAll(Iterable<int> musicIds) async {
    for (final musicId in musicIds) {
      await FavoriteConn.insertFavoriteMusic(musicId);
    }
    await refresh();
  }

  Future<void> remove(int? musicId) async {
    if (musicId == null) return;
    await FavoriteConn.deleteByMusicId(musicId);
    await refresh();
  }

  Future<void> togglePlaylist(int? playlistId) async {
    if (playlistId == null) return;
    if (isFavoritePlaylist(playlistId)) {
      await PlaylistConn.deleteFavoritePlaylist(playlistId);
    } else {
      await PlaylistConn.insertFavoritePlaylist(playlistId);
    }
    await refresh();
  }

  Future<void> addPlaylist(int? playlistId) async {
    if (playlistId == null) return;
    await PlaylistConn.insertFavoritePlaylist(playlistId);
    await refresh();
  }

  Future<void> removePlaylist(int? playlistId) async {
    if (playlistId == null) return;
    await PlaylistConn.deleteFavoritePlaylist(playlistId);
    await refresh();
  }
}
