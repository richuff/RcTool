class RecommendHistory {
  int id;
  String recommendDate;
  int createdAt;
  int musicCount;

  RecommendHistory(
    this.id,
    this.recommendDate,
    this.createdAt, {
    this.musicCount = 0,
  });
}
