/// 把字节数格式化成便于阅读的大小（缓存占用展示用）。
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 MB';
  final mb = bytes / (1024 * 1024);
  if (mb < 0.1) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (mb < 10) return '${mb.toStringAsFixed(2)} MB';
  return '${mb.toStringAsFixed(1)} MB';
}
