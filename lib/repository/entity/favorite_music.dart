class FavoriteMusic{
  int? id;
  int musicId;

  FavoriteMusic({
    this.id,
    required this.musicId,
  });

  @override
  String toString() {
    return 'FavoriteMusic{id: $id, musicId: $musicId}';
  }

  @override
  bool operator ==(Object other) {
    if (other is FavoriteMusic && other.id == id && other.musicId == musicId) {
      return true;
    }
    return false;
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'musicId': musicId};
  }
}