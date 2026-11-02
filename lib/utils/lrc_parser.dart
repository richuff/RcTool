/// @ClassName LyricLine
/// @Description 一行歌词：时间点 + 文本。同一时间点可能有多行（双语歌词）。
/// @Author richuff
/// @Version 1.0
class LyricLine {
  final Duration time;
  final String text;

  const LyricLine(this.time, this.text);

  @override
  String toString() => '${time.inMilliseconds}ms $text';
}

/// @ClassName LyricSheet
/// @Description LRC 歌词解析结果。支持一行多个时间戳、`[offset:]` 偏移、
///              无时间戳的纯文本歌词（此时 [synced] 为 false）。
class LyricSheet {
  /// 按时间升序排列的歌词行
  final List<LyricLine> lines;

  /// LRC 头部元信息（ti / ar / al / by …）
  final Map<String, String> tags;

  /// 文件内声明的偏移（毫秒），会被叠加到用户偏移之外
  final Duration offset;

  /// 是否存在时间戳（否则只能整段展示）
  final bool synced;

  const LyricSheet({
    required this.lines,
    required this.tags,
    required this.offset,
    required this.synced,
  });

  static const LyricSheet empty = LyricSheet(
    lines: [],
    tags: {},
    offset: Duration.zero,
    synced: false,
  );

  bool get isEmpty => lines.isEmpty;

  bool get isNotEmpty => lines.isNotEmpty;

  /// 返回当前时间应当高亮的行号；早于第一行时返回 0，歌词为空返回 -1。
  int indexAt(Duration position, {Duration userOffset = Duration.zero}) {
    if (lines.isEmpty) return -1;
    // 没有时间戳时无法定位，始终高亮第一行（视图上也不做滚动）
    if (!synced) return 0;
    final target =
        position.inMilliseconds - offset.inMilliseconds - userOffset.inMilliseconds;
    if (target < lines.first.time.inMilliseconds) return 0;

    var low = 0;
    var high = lines.length - 1;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (lines[mid].time.inMilliseconds <= target) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  /// 解析 LRC 文本。无法解析的行会被跳过，不会抛异常。
  static LyricSheet parse(String raw, {Duration userOffset = Duration.zero}) {
    if (raw.trim().isEmpty) return empty;

    final timeTag = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
    final metaTag = RegExp(r'^\[(ti|ar|al|by|offset|length|re|ve):(.*)\]$',
        caseSensitive: false);

    final tags = <String, String>{};
    final parsed = <LyricLine>[];
    var offset = Duration.zero;
    var sawTimestamp = false;

    for (final rawLine in raw.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final meta = metaTag.firstMatch(line);
      if (meta != null) {
        final key = meta.group(1)!.toLowerCase();
        final value = meta.group(2)!.trim();
        tags[key] = value;
        if (key == 'offset') {
          final ms = int.tryParse(value);
          if (ms != null) offset = Duration(milliseconds: ms);
        }
        continue;
      }

      final matches = timeTag.allMatches(line).toList();
      if (matches.isEmpty) {
        // 没有时间戳：当作纯文本歌词保留（synced 为 false 时按顺序显示）
        if (!sawTimestamp) {
          parsed.add(LyricLine(Duration.zero, line));
        }
        continue;
      }

      sawTimestamp = true;
      // 文本取最后一个时间标签之后的内容
      final last = matches.last;
      final text = line.substring(last.end).trim();
      if (text.isEmpty) continue;

      for (final match in matches) {
        final minutes = int.tryParse(match.group(1) ?? '') ?? 0;
        final seconds = int.tryParse(match.group(2) ?? '') ?? 0;
        final fraction = match.group(3);
        var millis = 0;
        if (fraction != null) {
          final value = int.tryParse(fraction) ?? 0;
          millis = switch (fraction.length) {
            1 => value * 100,
            2 => value * 10,
            _ => value,
          };
        }
        parsed.add(
          LyricLine(
            Duration(milliseconds: minutes * 60000 + seconds * 1000 + millis),
            text,
          ),
        );
      }
    }

    parsed.sort((a, b) => a.time.compareTo(b.time));

    // 去掉相邻的完全重复行（有些 LRC 会在同一时间重复写一遍）
    final deduped = <LyricLine>[];
    for (final line in parsed) {
      if (deduped.isNotEmpty &&
          deduped.last.time == line.time &&
          deduped.last.text == line.text) {
        continue;
      }
      deduped.add(line);
    }

    return LyricSheet(
      lines: deduped,
      tags: tags,
      offset: offset,
      synced: sawTimestamp,
    );
  }
}
