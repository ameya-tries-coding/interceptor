class AccountExtractor {
  static String? extract(String message) {
    final match = RegExp(r'(?:A/c|Ac|Acct|Account|Card|XX|[*])[^\d]*(\d+)', caseSensitive: false).firstMatch(message);
    if (match != null) {
      final digits = match.group(1)!;
      // Validation layer to reject very short captures
      if (digits.length < 3) return null;
      return digits;
    }
    return null;
  }
}
