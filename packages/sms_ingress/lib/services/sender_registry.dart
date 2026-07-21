class SenderRegistry {
  static String resolveBankCode(String sender) {
    final senderUpper = sender.toUpperCase();
    
    String code = senderUpper;
    final parts = senderUpper.split('-');
    if (parts.length >= 2) {
      code = parts[1];
    }
    
    if (code.contains("KOTAK")) return "KOTAK";
    if (code.contains("HDFC")) return "HDFC";
    if (code.contains("SBI")) return "SBI";
    if (code.contains("BOI")) return "BOI";
    if (code.contains("IDBI")) return "IDBI";
    if (code.contains("BOB")) return "BOB";
    if (code.contains("SARASW")) return "SARASWAT";
    if (code.contains("ICICI")) return "ICICI";
    
    return "UNKNOWN";
  }
}
