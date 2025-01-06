class CommUtil{
  static bool parseBool(String? value) {
    if (value == null) {
      return false;
    }
    return value.toLowerCase() == 'true';
  }
}