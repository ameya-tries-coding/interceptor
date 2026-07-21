import '../models/parsed_sms.dart';

abstract class BankParserStrategy {
  ParsedSms? parse(int id, String sender, String body, DateTime receivedTime);

  // Helper method for extracting common numeric values
  double? extractAmount(String body, RegExp regex) {
    final match = regex.firstMatch(body);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', ''));
    }
    return null;
  }
}

class KotakParser extends BankParserStrategy {
  @override
  ParsedSms? parse(int id, String sender, String body, DateTime receivedTime) {
    final bodyLower = body.toLowerCase();
    if (!bodyLower.contains("rs.") && !bodyLower.contains("inr")) return null;

    final isCredit = bodyLower.contains("received") || bodyLower.contains("credited");
    final isDebit = bodyLower.contains("sent") || bodyLower.contains("debited") || bodyLower.contains("paid");
    if (!isCredit && !isDebit) return null;

    final amount = extractAmount(body, RegExp(r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)', caseSensitive: false));
    final accountMatch = RegExp(r'(?:AC|A/c|A/C)[^\d]*(\d+)', caseSensitive: false).firstMatch(body);
    final account = accountMatch?.group(1);
    
    String? merchant;
    final merchantMatches = RegExp(r'(?:to|from)\s+([a-zA-Z0-9@.-]+)', caseSensitive: false).allMatches(body);
    for (final m in merchantMatches) {
      final name = m.group(1)!;
      final nameL = name.toLowerCase();
      if (nameL.contains("bank") || nameL == "ac" || nameL == "kotak") continue;
      merchant = name;
      if (name.contains("@")) break;
    }

    final dateMatch = RegExp(r'on\s+(\d{2}-\d{2}-\d{2}|\d{2}\s+[a-zA-Z]{3}\s+\d{2,4})').firstMatch(body);
    final upiMatch = RegExp(r'(?:UPI Ref|Ref\.? No\.?|UTR)\s*[:\-]?\s*(\d+)', caseSensitive: false).firstMatch(body);

    return ParsedSms(
      smsId: id, rawSms: body, sender: sender, amount: amount, accountLastDigits: account,
      merchant: merchant, transactionDate: dateMatch?.group(1), smsReceivedTime: receivedTime,
      upiReference: upiMatch?.group(1), isCredit: isCredit,
    );
  }
}

class HdfcParser extends BankParserStrategy {
  @override
  ParsedSms? parse(int id, String sender, String body, DateTime receivedTime) {
    final bodyLower = body.toLowerCase();
    
    // Check if mandate
    if (bodyLower.contains("mandate") || bodyLower.contains("deducted on")) {
      return null; // Skip mandates for now
    }

    final isCredit = bodyLower.contains("credited");
    final isDebit = bodyLower.contains("sent") || bodyLower.contains("debited");
    if (!isCredit && !isDebit) return null;

    final amount = extractAmount(body, RegExp(r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)', caseSensitive: false));
    
    // HDFC A/C format is usually A/c xx4316 or A/C *2894
    final accountMatch = RegExp(r'A/c\s*[xX*]+(\d+)', caseSensitive: false).firstMatch(body);
    
    String? merchant;
    if (isCredit) {
      final vpaMatch = RegExp(r'from VPA\s+([a-zA-Z0-9@.-]+)', caseSensitive: false).firstMatch(body);
      merchant = vpaMatch?.group(1);
    } else {
      final toMatch = RegExp(r'To\s+([^\n]+)', caseSensitive: false).firstMatch(body);
      merchant = toMatch?.group(1)?.trim();
    }

    final upiMatch = RegExp(r'(?:UPI\s*|Ref\s*)(\d+)', caseSensitive: false).firstMatch(body);
    final dateMatch = RegExp(r'on\s+(\d{2}-\d{2}-\d{2})|On\s+(\d{2}/\d{2}/\d{2})', caseSensitive: false).firstMatch(body);

    return ParsedSms(
      smsId: id, rawSms: body, sender: sender, amount: amount, accountLastDigits: accountMatch?.group(1),
      merchant: merchant, transactionDate: dateMatch?.group(1) ?? dateMatch?.group(2), 
      smsReceivedTime: receivedTime, upiReference: upiMatch?.group(1), isCredit: isCredit,
    );
  }
}

class SbiParser extends BankParserStrategy {
  @override
  ParsedSms? parse(int id, String sender, String body, DateTime receivedTime) {
    final bodyLower = body.toLowerCase();
    final isCredit = bodyLower.contains("credited");
    final isDebit = bodyLower.contains("debited");
    if (!isCredit && !isDebit) return null;

    final amount = extractAmount(body, RegExp(r'(?:by|Rs\.?)\s*([\d,]+\.?\d*)', caseSensitive: false));
    final accountMatch = RegExp(r'A/c\s*[xX*]+(\d+)', caseSensitive: false).firstMatch(body);
    
    String? merchant;
    if (isDebit) {
      final merchantMatch = RegExp(r'(?:trf to|transfer to)\s+(.*?)\s+(?:Refno|Ref No)', caseSensitive: false).firstMatch(body);
      merchant = merchantMatch?.group(1)?.trim();
    } else {
      final merchantMatch = RegExp(r'(?:trf from|transfer from)\s+(.*?)\s+(?:Refno|Ref No)', caseSensitive: false).firstMatch(body);
      merchant = merchantMatch?.group(1)?.trim();
    }

    final upiMatch = RegExp(r'Ref\s?No\.?\s*(\d+)', caseSensitive: false).firstMatch(body);
    final dateMatch = RegExp(r'(?:date|on)\s+(\d{2}[a-zA-Z]{3}\d{2})', caseSensitive: false).firstMatch(body);

    return ParsedSms(
      smsId: id, rawSms: body, sender: sender, amount: amount, accountLastDigits: accountMatch?.group(1),
      merchant: merchant, transactionDate: dateMatch?.group(1), smsReceivedTime: receivedTime,
      upiReference: upiMatch?.group(1), isCredit: isCredit,
    );
  }
}

class BoiParser extends BankParserStrategy {
  @override
  ParsedSms? parse(int id, String sender, String body, DateTime receivedTime) {
    final bodyLower = body.toLowerCase();
    final isCredit = bodyLower.contains("credited to your");
    final isDebit = bodyLower.contains("debited");
    if (!isCredit && !isDebit) return null;

    final amount = extractAmount(body, RegExp(r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)', caseSensitive: false));
    final accountMatch = RegExp(r'A/c[xX*]+(\d+)|Ac\s*[xX*]+(\d+)', caseSensitive: false).firstMatch(body);
    
    String? merchant;
    if (isDebit) {
      final merchantMatch = RegExp(r'credited to\s+(.*?)\s+via', caseSensitive: false).firstMatch(body);
      merchant = merchantMatch?.group(1)?.trim();
    }

    final upiMatch = RegExp(r'UPI [rR]ef [Nn]o\.?\s*(\d+)', caseSensitive: false).firstMatch(body);
    final dateMatch = RegExp(r'on\s+(\d{2}[a-zA-Z]{3}\d{2}|\d{2}-\d{2}-\d{2})', caseSensitive: false).firstMatch(body);

    return ParsedSms(
      smsId: id, rawSms: body, sender: sender, amount: amount, 
      accountLastDigits: accountMatch?.group(1) ?? accountMatch?.group(2),
      merchant: merchant, transactionDate: dateMatch?.group(1), smsReceivedTime: receivedTime,
      upiReference: upiMatch?.group(1), isCredit: isCredit,
    );
  }
}

class IdbiParser extends BankParserStrategy {
  @override
  ParsedSms? parse(int id, String sender, String body, DateTime receivedTime) {
    final bodyLower = body.toLowerCase();
    
    final isCredit = bodyLower.startsWith("credit:-") || bodyLower.contains("is credited with");
    final isDebit = bodyLower.startsWith("debit:-") || bodyLower.contains("is debited with");
    if (!isCredit && !isDebit) return null;

    final amount = extractAmount(body, RegExp(r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)', caseSensitive: false));
    final accountMatch = RegExp(r'(?:Acct|A/c)\s*[xX*]+(\d+)', caseSensitive: false).firstMatch(body);
    
    String? merchant;
    if (isDebit) {
      final merchantMatch = RegExp(r'to\s+(.*?)\.\s*UPI:', caseSensitive: false).firstMatch(body);
      merchant = merchantMatch?.group(1)?.trim();
      
      if (merchant == null) {
        final oldMerchantMatch = RegExp(r'Bal Rs[\d\s.]+(.*?)\s+credited\.', caseSensitive: false).firstMatch(body);
        merchant = oldMerchantMatch?.group(1)?.trim();
      }
    } else {
      final merchantMatch = RegExp(r'from\s+(.*?)\.\s*UPI:', caseSensitive: false).firstMatch(body);
      merchant = merchantMatch?.group(1)?.trim();
    }

    final upiMatch = RegExp(r'UPI[:\s]*(\d+)', caseSensitive: false).firstMatch(body);
    final dateMatch = RegExp(r'on\s+(\d{2}-[a-zA-Z]{3}-\d{2,4})', caseSensitive: false).firstMatch(body);

    return ParsedSms(
      smsId: id, rawSms: body, sender: sender, amount: amount, accountLastDigits: accountMatch?.group(1),
      merchant: merchant, transactionDate: dateMatch?.group(1), smsReceivedTime: receivedTime,
      upiReference: upiMatch?.group(1), isCredit: isCredit,
    );
  }
}

class SaraswatParser extends BankParserStrategy {
  @override
  ParsedSms? parse(int id, String sender, String body, DateTime receivedTime) {
    final bodyLower = body.toLowerCase();
    final isDebit = bodyLower.contains("debited");
    if (!isDebit) return null;

    final amount = extractAmount(body, RegExp(r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)', caseSensitive: false));
    final accountMatch = RegExp(r'XX(\d+)', caseSensitive: false).firstMatch(body); // Card ending
    
    final merchantMatch = RegExp(r'at\s+(.*?)\s+The available', caseSensitive: false).firstMatch(body);
    
    final upiMatch = RegExp(r'Txn Ref No\s*(\d+)', caseSensitive: false).firstMatch(body);
    final dateMatch = RegExp(r'on\s+(\d{2}-[a-zA-Z]{3}-\d{4})', caseSensitive: false).firstMatch(body);

    return ParsedSms(
      smsId: id, rawSms: body, sender: sender, amount: amount, accountLastDigits: accountMatch?.group(1),
      merchant: merchantMatch?.group(1)?.trim(), transactionDate: dateMatch?.group(1), 
      smsReceivedTime: receivedTime, upiReference: upiMatch?.group(1), isCredit: false,
    );
  }
}

class BobParser extends BankParserStrategy {
  @override
  ParsedSms? parse(int id, String sender, String body, DateTime receivedTime) {
    final bodyLower = body.toLowerCase();
    final isCredit = bodyLower.contains("credited") || bodyLower.contains("cr.");
    final isDebit = bodyLower.contains("dr.");
    if (!isCredit && !isDebit) return null;

    final amount = extractAmount(body, RegExp(r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)', caseSensitive: false));
    final accountMatch = RegExp(r'(?:A/C\s*[xX*]+|XXXXXX)(\d+)', caseSensitive: false).firstMatch(body);
    
    String? merchant;
    if (isDebit) {
      final merchantMatch = RegExp(r'Cr\.\s*to\s+([a-zA-Z0-9@.-]+)', caseSensitive: false).firstMatch(body);
      merchant = merchantMatch?.group(1)?.trim();
    }

    final upiMatch = RegExp(r'(?:UPI Ref No|Ref:)\s*(\d+)', caseSensitive: false).firstMatch(body);
    final dateMatch = RegExp(r'on\s+(\d{4}-\d{2}-\d{2})', caseSensitive: false).firstMatch(body);

    return ParsedSms(
      smsId: id, rawSms: body, sender: sender, amount: amount, accountLastDigits: accountMatch?.group(1),
      merchant: merchant, transactionDate: dateMatch?.group(1), smsReceivedTime: receivedTime,
      upiReference: upiMatch?.group(1), isCredit: isCredit,
    );
  }
}
class DefaultParser extends BankParserStrategy {
  @override
  ParsedSms? parse(int id, String sender, String body, DateTime receivedTime) {
    final bodyLower = body.toLowerCase();
    
    // Strict payment keyword check since we don't know the bank format
    final hasPaymentKeywords = bodyLower.contains("upi ref") || 
                               bodyLower.contains("debited") || 
                               bodyLower.contains("credited") || 
                               bodyLower.contains("rs.") || 
                               bodyLower.contains("inr");
                               
    if (!hasPaymentKeywords) return null;

    final isCredit = bodyLower.contains("received") || bodyLower.contains("credited") || bodyLower.contains("cr.");
    final isDebit = bodyLower.contains("sent") || bodyLower.contains("paid") || bodyLower.contains("debited") || bodyLower.contains("dr.");

    final amount = extractAmount(body, RegExp(r'(?:Rs\.?|INR|by)\s*([\d,]+\.?\d*)', caseSensitive: false));
    final accountMatch = RegExp(r'(?:AC|A/c|A/C)[^\d]*(\d+)', caseSensitive: false).firstMatch(body);
    
    String? merchant;
    final merchantMatches = RegExp(r'(?:to|from)\s+([a-zA-Z0-9@.-]+)', caseSensitive: false).allMatches(body);
    for (final m in merchantMatches) {
      final name = m.group(1)!;
      final nameL = name.toLowerCase();
      if (nameL.contains("bank") || nameL == "ac") continue;
      merchant = name;
      if (name.contains("@")) break;
    }

    final upiMatch = RegExp(r'(?:UPI Ref|Ref\.? No\.?|UTR|Refno)\s*[:\-]?\s*(\d+)', caseSensitive: false).firstMatch(body);
    final dateMatch = RegExp(r'(?:on|date)\s+(\d{2}-\d{2}-\d{2}|\d{4}-\d{2}-\d{2}|\d{2}[a-zA-Z]{3}\d{2,4})', caseSensitive: false).firstMatch(body);

    return ParsedSms(
      smsId: id, rawSms: body, sender: sender, amount: amount, 
      accountLastDigits: accountMatch?.group(1), merchant: merchant, 
      transactionDate: dateMatch?.group(1), smsReceivedTime: receivedTime,
      upiReference: upiMatch?.group(1), isCredit: isCredit == true || isDebit == false,
    );
  }
}

class IciciParser extends BankParserStrategy {
  @override
  ParsedSms? parse(int id, String sender, String body, DateTime receivedTime) {
    // Flatten body to remove newlines for easier regex parsing
    final cleanBody = body.replaceAll('\n', ' ').replaceAll('\r', ' ');
    final bodyLower = cleanBody.toLowerCase();
    
    bool isCredit = false;
    if (bodyLower.contains("debited for") || bodyLower.contains("debited from")) {
      isCredit = false;
    } else if (bodyLower.contains("credited:") || bodyLower.contains("credited with") || bodyLower.contains("credited to")) {
      isCredit = true;
    } else {
      return null;
    }

    final amount = extractAmount(cleanBody, RegExp(r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)', caseSensitive: false));
    final accountMatch = RegExp(r'(?:Acct|Account)\s*[xX*]+(\d+)', caseSensitive: false).firstMatch(cleanBody);
    
    String? merchant;
    if (!isCredit) {
      final merchantMatch = RegExp(r';\s*(.*?)\s+credited\.', caseSensitive: false).firstMatch(cleanBody);
      merchant = merchantMatch?.group(1)?.trim();
    } else {
      final merchantMatch = RegExp(r'Info\s*(.*?)\.\s*Available', caseSensitive: false).firstMatch(cleanBody);
      merchant = merchantMatch?.group(1)?.trim();
    }

    final upiMatch = RegExp(r'UPI[:\s]*(\d+)', caseSensitive: false).firstMatch(cleanBody);
    final dateMatch = RegExp(r'on\s+(\d{2}-[a-zA-Z]{3}-\d{2})', caseSensitive: false).firstMatch(cleanBody);

    return ParsedSms(
      smsId: id, rawSms: body, sender: sender, amount: amount, accountLastDigits: accountMatch?.group(1),
      merchant: merchant, transactionDate: dateMatch?.group(1), smsReceivedTime: receivedTime,
      upiReference: upiMatch?.group(1), isCredit: isCredit,
    );
  }
}
