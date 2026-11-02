import '../repository/entity/playlist.dart';

/// 「我的喜欢」作为一个内置的默认歌单：
/// 它不对应 playlist 表里的真实行（收藏关系存在 favorite_music 表），
/// 因此在歌单列表里用一个固定的虚拟 id 表示，详情页按 id 分流数据源。
const int kFavoritePlaylistId = -1;

const String kFavoritePlaylistName = '我的喜欢';

/// 每日推荐等内部生成的歌单名以该前缀开头，不在歌单列表里展示。
const String kRecommendPlaylistPrefix = '每日推荐 ';

bool isFavoritePlaylistId(int? id) => id == kFavoritePlaylistId;

/// 构造「我的喜欢」这个默认歌单。
Playlist favoritePlaylist({int musicCount = 0}) {
  return Playlist(
    kFavoritePlaylistId,
    kFavoritePlaylistName,
    0,
    musicCount: musicCount,
  );
}

/// 是否为内部歌单（每日推荐快照），不进入歌单列表。
bool isInternalPlaylist(Playlist playlist) {
  return playlist.name.startsWith(kRecommendPlaylistPrefix);
}
