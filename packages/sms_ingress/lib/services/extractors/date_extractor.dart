class DateExtractor {
  static String? extract(String message) {
    final match = RegExp(r'(?:on|date)\s+(\d{2}[-/a-zA-Z]+\d{2,4})', caseSensitive: false).firstMatch(message);
    return match?.group(1);
  }
}
