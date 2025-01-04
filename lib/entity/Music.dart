class Music{
  String url;
  String imageUrl;
  String songName;
  String decoration;

  Music(this.url,this.imageUrl,this.songName,this.decoration);

  @override
  String toString() {
    return "url:$url,imageUrl:$imageUrl,songName:$songName,decoration:$decoration";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other) ||
        other is Music && other.url == url && other.imageUrl == imageUrl && other.songName == songName && other.decoration == decoration){
      return true;
    }
    return false;
  }


}