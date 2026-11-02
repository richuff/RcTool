/// @ClassName LyricRecord
/// @Description 本地保存的一份歌词：LRC 原文 + 用户微调的偏移（毫秒）。
/// @Author richuff
/// @Version 1.0
class LyricRecord {
  final String url;
  final String content;
  final int offsetMs;
  final int updatedAt;

  const LyricRecord({
    required this.url,
    required this.content,
    this.offsetMs = 0,
    this.updatedAt = 0,
  });
}
