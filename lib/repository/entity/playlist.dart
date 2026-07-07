class Playlist {
  int? id;
  String name;
  int createdAt;
  int musicCount;

  Playlist(this.id, this.name, this.createdAt, {this.musicCount = 0});

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'createdAt': createdAt,
    };
  }
}
