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
    if (isFavorite(musicId)) {
      await FavoriteConn.deleteByMusicId(musicId);
    } else {
      await FavoriteConn.insertFavoriteMusic(musicId);
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
