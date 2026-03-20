class Music {
  int? id;
  String url;
  String imageUrl;
  String songName;
  String decoration;

  Music(this.id,this.url, this.imageUrl, this.songName, this.decoration);

  @override
  String toString() {
    return "id:$id,url:$url,imageUrl:$imageUrl,songName:$songName,decoration:$decoration";
  }

  @override
  bool operator ==(Object other) {
    if (other is Music && other.id == id && other.url == url && other.imageUrl == imageUrl &&
        other.songName == songName && other.decoration == decoration) {
      return true;
    }
    return false;
  }

  Map<String, Object?> toMap() {
    return {
      'url': url,
      'imageUrl': imageUrl,
      'songName': songName,
      'decoration': decoration};
  }
}