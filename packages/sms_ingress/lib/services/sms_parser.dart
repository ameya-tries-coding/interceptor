import '../models/parsed_sms.dart';
import 'bank_parsers.dart';

class SmsParser {
  // O(1) Runtime Cache to instantly resolve known sender IDs
  static final Map<String, BankParserStrategy> _parserCache = {};

  static ParsedSms? parse(int id, String sender, String body, DateTime receivedTime) {
    final senderUpper = sender.toUpperCase();

    // 1. Mandatory Promotional Filter: Only parse -S (Transactional) or -T (OTP/Transaction)
    // This explicitly blocks -P (Promotional) tags.
    if (!senderUpper.endsWith("-S") && !senderUpper.contains("-S-") && 
        !senderUpper.endsWith("-T") && !senderUpper.contains("-T-")) {
      return null; // Drop promotional messages immediately
    }

    // 2. Check Cache First (O(1) Lookup)
    BankParserStrategy? strategy = _parserCache[senderUpper];

    // 3. If not in cache, resolve it
    if (strategy == null) {
      // Isolate the Bank Code by splitting out the Telecom prefixes (XY-) and suffixes (-S)
      String bankCode = senderUpper;
      final parts = senderUpper.split('-');
      if (parts.length >= 2) {
        bankCode = parts[1]; // Extracts "HDFCBK" from "AD-HDFCBK-S"
      }

      if (bankCode.contains("KOTAK")) {
        strategy = KotakParser();
      } else if (bankCode.contains("HDFC")) {
        strategy = HdfcParser();
      } else if (bankCode.contains("SBI")) {
        strategy = SbiParser();
      } else if (bankCode.contains("BOI")) {
        strategy = BoiParser();
      } else if (bankCode.contains("IDBI")) {
        strategy = IdbiParser();
      } else if (bankCode.contains("BOB")) {
        strategy = BobParser();
      } else if (bankCode.contains("SARASW")) {
        strategy = SaraswatParser();
      } else if (bankCode.contains("ICICI")) {
        strategy = IciciParser();
      } else {
        // Fallback for unknown banks
        strategy = DefaultParser();
      }

      // Cache the resolved strategy so future SMS from this exact sender are O(1)
      _parserCache[senderUpper] = strategy;
    }

    // Call the specific strategy
    final parsedSms = strategy.parse(id, sender, body, receivedTime);

    // Ensure it was a valid transaction by checking if amount exists
    if (parsedSms != null && parsedSms.amount != null) {
      return parsedSms;
    }

    return null;
  }
}
