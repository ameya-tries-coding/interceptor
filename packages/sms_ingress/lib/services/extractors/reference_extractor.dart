class ReferenceExtractor {
  static String? extract(String message) {
    final match = RegExp(r'(?:UPI Ref|Ref\.? No\.?|UTR|Txn Ref|UPI[:\s]*|Ref[:\s]*)\s*[:\-]?\s*(\d{6,})', caseSensitive: false).firstMatch(message);
    return match?.group(1);
  }
}
