import '../models/parsed_sms.dart';
import 'bank_parsers.dart';
import 'sender_registry.dart';
import 'global_parser_engine.dart';

class SmsParser {
  // O(1) Runtime Cache to instantly resolve known sender IDs
  static final Map<String, BankParserOverride> _parserCache = {};

  static ParsedSms? parse(int id, String sender, String body, DateTime receivedTime) {
    final senderUpper = sender.toUpperCase();

    // 1. Mandatory Promotional Filter: Only parse -S (Transactional) or -T (OTP/Transaction)
    if (!senderUpper.endsWith("-S") && !senderUpper.contains("-S-") && 
        !senderUpper.endsWith("-T") && !senderUpper.contains("-T-")) {
      return null;
    }

    // 2. Global Baseline Extraction (includes Gatekeeper)
    ParsedSms? baseline = GlobalParserEngine.extractBaseline(id, sender, body, receivedTime);
    if (baseline == null) return null;

    // 3. Resolve Bank Code
    String bankCode = SenderRegistry.resolveBankCode(senderUpper);

    // 4. Find Override Strategy
    BankParserOverride? strategy = _parserCache[bankCode];
    if (strategy == null) {
      if (bankCode == "KOTAK") strategy = KotakParser();
      else if (bankCode == "HDFC") strategy = HdfcParser();
      else if (bankCode == "SBI") strategy = SbiParser();
      else if (bankCode == "BOI") strategy = BoiParser();
      else if (bankCode == "IDBI") strategy = IdbiParser();
      else if (bankCode == "BOB") strategy = BobParser();
      else if (bankCode == "SARASWAT") strategy = SaraswatParser();
      else if (bankCode == "ICICI") strategy = IciciParser();
      else strategy = DefaultParser();

      _parserCache[bankCode] = strategy;
    }

    // 5. Apply Overrides
    final finalParsed = strategy.applyOverride(baseline);

    if (finalParsed.amount != null) {
      return finalParsed;
    }

    return null;
  }
}
