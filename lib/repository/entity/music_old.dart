@Deprecated("移除isFavorite字段")
class MusicOld {
  String url;
  String imageUrl;
  String songName;
  String decoration;
  bool isFavorite;

  MusicOld(this.url, this.imageUrl, this.songName, this.decoration,
      this.isFavorite);

  @override
  String toString() {
    return "url:$url,imageUrl:$imageUrl,songName:$songName,decoration:$decoration,isFavorite:$isFavorite";
  }

  @override
  bool operator ==(Object other) {
    if (other is MusicOld && other.url == url && other.imageUrl == imageUrl &&
        other.songName == songName && other.decoration == decoration &&
        isFavorite == isFavorite) {
      return true;
    }
    return false;
  }

  Map<String, Object?> toMap() {
    return {
      'url': url,
      'imageUrl': imageUrl,
      'songName': songName,
      'decoration': decoration,
      'isFavorite': isFavorite == true ? 1 : 0};
  }
}