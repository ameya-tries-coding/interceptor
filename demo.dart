enum TransactionType { credit, debit, unknown }

class ParsedTransaction {
  TransactionType type;
  double amount;
  String account;
  String merchant;
  String rawSms;

  ParsedTransaction({
    this.type = TransactionType.unknown,
    this.amount = 0.0,
    this.account = "",
    this.merchant = "",
    required this.rawSms,
  });

  @override
  String toString() {
    return 'Amount: ${amount.toStringAsFixed(2).padRight(8)} | Type: ${type.name.padRight(6)} | Merchant: ${merchant.padRight(15)} | Acc: $account';
  }
}

class SmsParser {
  static ParsedTransaction parseBankSms(String sms) {
    var result = ParsedTransaction(rawSms: sms);
    String smsLower = sms.toLowerCase();

    // 1. Transaction Type
    if (RegExp(r'\b(debited|deducted|spent|paid|sent|dr)\b', caseSensitive: false).hasMatch(smsLower)) {
      result.type = TransactionType.debit;
    } else if (RegExp(r'\b(credited|received|added|refunded|cr)\b', caseSensitive: false).hasMatch(smsLower)) {
      result.type = TransactionType.credit;
    }

    // 2. Amount Extraction
    // Matches Rs., INR, rs followed by optional spaces and the number
    var amountMatch = RegExp(r'(?:rs\.?|inr)\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(sms);
    if (amountMatch != null && amountMatch.groupCount >= 1) {
      String cleanAmount = amountMatch.group(1)!.replaceAll(',', '');
      result.amount = double.tryParse(cleanAmount) ?? 0.0;
    }

    // 3. Account/Card Extraction
    // Looks for 4 or more digits after common account/card prefixes
    var accountMatch = RegExp(r'(?:a/c|acct|account|card)[^\d]*(\d{4,})', caseSensitive: false).firstMatch(sms);
    if (accountMatch != null && accountMatch.groupCount >= 1) {
      result.account = accountMatch.group(1)!;
    }

    // 4. Merchant/Counterparty Extraction (Fallback Cascade)
    List<RegExp> merchantPatterns = [
      // Priority 1: Standard NPCI UPI format (e.g., UPI/P2M/12345/Zomato/...)
      RegExp(r'UPI/(?:[^/]+/){2}([^/]+)', caseSensitive: false),
      
      // Priority 2: Standard UPI VPA handles (e.g., to username@okaxis)
      RegExp(r'(?:to|from)\s+([a-zA-Z0-9.\-_]+@[a-zA-Z]+)', caseSensitive: false),
      
      // Priority 3: Semantic mapping for POS or online gateways
      RegExp(r'(?:at|towards|to|from)\s+([A-Za-z0-9\s&*-]+?)(?:\s+(?:on|via|av|avl|bal|ref|upi|card|date|time)|[.!?]|$)', caseSensitive: false)
    ];

    for (var pattern in merchantPatterns) {
      var match = pattern.firstMatch(sms);
      if (match != null && match.groupCount >= 1) {
        String extracted = match.group(1)!.trim();
        
        // Clean up "VPA " prefix if the bank included it
        if (extracted.toUpperCase().startsWith('VPA ')) {
          extracted = extracted.substring(4).trim();
        }
        
        // Ensure we didn't just capture a bank keyword
        if (extracted.length > 1 && extracted.toUpperCase() != 'UPI') {
          result.merchant = extracted;
          break; // Stop at the first successful regex match
        }
      }
    }

    return result;
  }
}

void main() {
  List<String> testMessages = [
    "INR 250.00 debited from A/c XX4532 on 12-Mar. UPI/P2M/409876/Zomato/UPI. Balance: INR 23,400.",
    "Your A/C XX1234 has been credited with Rs. 1,500.00 from rahul.sharma@okhdfcbank on 22/05/26.",
    "Dear Customer, txn of INR 100.00 via Debit Card ending 9988 done on 22May26 at AMAZON INDIA. Avail Bal: INR 50.00",
    "Rs.500.00 debited from a/c **3321 towards Netflix Subscription. Ref 1234. Avl Bal Rs.100",
  ];

  for (var msg in testMessages) {
    var parsed = SmsParser.parseBankSms(msg);
    print(parsed.toString());
  }
}