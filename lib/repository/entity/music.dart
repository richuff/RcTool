class Music {
  int? id;
  String url;
  String imageUrl;
  String songName;
  String decoration;

  Music(this.id, this.url, this.imageUrl, this.songName, this.decoration);

  @override
  String toString() {
    return "id:$id,url:$url,imageUrl:$imageUrl,songName:$songName,decoration:$decoration";
  }

  @override
  bool operator ==(Object other) {
    if (other is Music &&
        other.id == id &&
        other.url == url &&
        other.imageUrl == imageUrl &&
        other.songName == songName &&
        other.decoration == decoration) {
      return true;
    }
    return false;
  }

  Map<String, Object?> toMap() {
    return {
      'url': url,
      'imageUrl': imageUrl,
      'songName': songName,
      'decoration': decoration
    };
  }

  /// 断点续播用：完整保存队列里的每一首歌
  Map<String, Object?> toJson() {
    return {
      'id': id,
      'url': url,
      'imageUrl': imageUrl,
      'songName': songName,
      'decoration': decoration,
    };
  }

  static Music? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final url = raw['url'];
    if (url is! String || url.isEmpty) return null;
    return Music(
      raw['id'] is num ? (raw['id'] as num).toInt() : null,
      url,
      raw['imageUrl'] is String ? raw['imageUrl'] as String : '',
      raw['songName'] is String ? raw['songName'] as String : '',
      raw['decoration'] is String ? raw['decoration'] as String : '',
    );
  }
}
