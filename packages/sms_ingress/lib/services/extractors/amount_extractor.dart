class AmountExtractor {
  static double? extract(String message) {
    final match = RegExp(r'(?:Rs\.?|INR|₹|by)\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(message);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', ''));
    }
    return null;
  }
}
