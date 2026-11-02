import 'Music.dart';

/// 一次实际播放行为的历史记录。
class PlayHistory {
  final int? id;
  final String url;
  final String imageUrl;
  final String songName;
  final String decoration;
  final DateTime playedAt;

  const PlayHistory({
    this.id,
    required this.url,
    required this.imageUrl,
    required this.songName,
    required this.decoration,
    required this.playedAt,
  });

  factory PlayHistory.fromMap(Map<String, Object?> map) {
    return PlayHistory(
      id: map['id'] as int?,
      url: map['url'] as String,
      imageUrl: map['imageUrl'] as String,
      songName: map['songName'] as String,
      decoration: map['decoration'] as String,
      playedAt: DateTime.fromMillisecondsSinceEpoch(map['playedAt'] as int),
    );
  }

  Music toMusic() => Music(null, url, imageUrl, songName, decoration);
}

/// 按歌曲聚合后的播放统计。
class PlayedSongSummary {
  final Music music;
  final int playCount;
  final DateTime lastPlayedAt;

  const PlayedSongSummary({
    required this.music,
    required this.playCount,
    required this.lastPlayedAt,
  });
}
