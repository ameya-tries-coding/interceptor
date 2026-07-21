class MerchantCleaner {
  static String? clean(String? rawMerchant) {
    if (rawMerchant == null || rawMerchant.trim().isEmpty) return null;
    
    String cleaned = rawMerchant.trim();
    
    // Remove common noisy suffixes
    final suffixes = [
      ' private limited', ' pvt ltd', ' pvt. ltd.', ' ltd', ' limited', 
      ' inc', ' corp', ' llc'
    ];
    
    String lower = cleaned.toLowerCase();
    for (final suffix in suffixes) {
      if (lower.endsWith(suffix)) {
        cleaned = cleaned.substring(0, cleaned.length - suffix.length).trim();
        lower = cleaned.toLowerCase();
      }
    }

    // Remove random REF / UPI fragments that sometimes get attached
    cleaned = cleaned.replaceAll(RegExp(r'(?:\s+ref\s*\d+|\s+upi.*)', caseSensitive: false), '').trim();
    
    if (cleaned.isEmpty) return null;
    return cleaned;
  }
}
