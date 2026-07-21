class MerchantExtractor {
  static String? extract(String message, bool isIncome) {
    // Generic fallback extraction
    String? merchant;
    if (!isIncome) {
      final match = RegExp(r'(?:to|at|for)\s+([a-zA-Z0-9@.-]+)', caseSensitive: false).firstMatch(message);
      merchant = match?.group(1);
    } else {
      final match = RegExp(r'from\s+([a-zA-Z0-9@.-]+)', caseSensitive: false).firstMatch(message);
      merchant = match?.group(1);
    }
    
    final lower = merchant?.toLowerCase();
    if (lower != null && (lower.contains("bank") || lower == "ac" || lower == "rs" || lower == "rs." || lower == "inr" || lower == "₹")) {
      return null;
    }
    return merchant;
  }
}
