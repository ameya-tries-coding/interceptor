import '../models/parsed_sms.dart';

abstract class BankParserOverride {
  ParsedSms applyOverride(ParsedSms baseline);
}

class KotakParser extends BankParserOverride {
  @override
  ParsedSms applyOverride(ParsedSms baseline) {
    return baseline;
  }
}

class HdfcParser extends BankParserOverride {
  @override
  ParsedSms applyOverride(ParsedSms baseline) {
    final body = baseline.rawSms;
    final isCredit = baseline.isCredit == true;
    String? merchant = baseline.merchant;
    
    if (isCredit) {
      final vpaMatch = RegExp(r'from VPA\s+([a-zA-Z0-9@.-]+)', caseSensitive: false).firstMatch(body);
      if (vpaMatch != null) merchant = vpaMatch.group(1);
    } else {
      final toMatch = RegExp(r'To\s+([^\n]+)', caseSensitive: false).firstMatch(body);
      if (toMatch != null) merchant = toMatch.group(1)?.trim();
    }
    return baseline.copyWith(merchant: merchant);
  }
}

class SbiParser extends BankParserOverride {
  @override
  ParsedSms applyOverride(ParsedSms baseline) {
    final body = baseline.rawSms;
    final isDebit = baseline.isCredit == false;
    String? merchant = baseline.merchant;

    if (isDebit) {
      final merchantMatch = RegExp(r'(?:trf to|transfer to)\s+(.*?)\s+(?:Refno|Ref No)', caseSensitive: false).firstMatch(body);
      if (merchantMatch != null) merchant = merchantMatch.group(1)?.trim();
    } else {
      final merchantMatch = RegExp(r'(?:trf from|transfer from)\s+(.*?)\s+(?:Refno|Ref No)', caseSensitive: false).firstMatch(body);
      if (merchantMatch != null) merchant = merchantMatch.group(1)?.trim();
    }
    return baseline.copyWith(merchant: merchant);
  }
}

class BoiParser extends BankParserOverride {
  @override
  ParsedSms applyOverride(ParsedSms baseline) {
    final body = baseline.rawSms;
    final isDebit = baseline.isCredit == false;
    String? merchant = baseline.merchant;
    
    if (isDebit) {
      final merchantMatch = RegExp(r'credited to\s+(.*?)\s+via', caseSensitive: false).firstMatch(body);
      if (merchantMatch != null) merchant = merchantMatch.group(1)?.trim();
    }
    return baseline.copyWith(merchant: merchant);
  }
}

class IdbiParser extends BankParserOverride {
  @override
  ParsedSms applyOverride(ParsedSms baseline) {
    final body = baseline.rawSms;
    final isDebit = baseline.isCredit == false;
    String? merchant = baseline.merchant;
    
    if (isDebit) {
      final merchantMatch = RegExp(r'to\s+(.*?)\.\s*UPI:', caseSensitive: false).firstMatch(body);
      if (merchantMatch != null) {
        merchant = merchantMatch.group(1)?.trim();
      } else {
        final oldMerchantMatch = RegExp(r'Bal Rs[\d\s.]+(.*?)\s+credited\.', caseSensitive: false).firstMatch(body);
        if (oldMerchantMatch != null) merchant = oldMerchantMatch.group(1)?.trim();
      }
    } else {
      final merchantMatch = RegExp(r'from\s+(.*?)\.\s*UPI:', caseSensitive: false).firstMatch(body);
      if (merchantMatch != null) merchant = merchantMatch.group(1)?.trim();
    }
    return baseline.copyWith(merchant: merchant);
  }
}

class SaraswatParser extends BankParserOverride {
  @override
  ParsedSms applyOverride(ParsedSms baseline) {
    final body = baseline.rawSms;
    final merchantMatch = RegExp(r'at\s+(.*?)\s+The available', caseSensitive: false).firstMatch(body);
    String? merchant = baseline.merchant;
    if (merchantMatch != null) merchant = merchantMatch.group(1)?.trim();
    
    return baseline.copyWith(merchant: merchant);
  }
}

class BobParser extends BankParserOverride {
  @override
  ParsedSms applyOverride(ParsedSms baseline) {
    final body = baseline.rawSms;
    final isDebit = baseline.isCredit == false;
    String? merchant = baseline.merchant;
    
    if (isDebit) {
      final merchantMatch = RegExp(r'Cr\.\s*to\s+([a-zA-Z0-9@.-]+)', caseSensitive: false).firstMatch(body);
      if (merchantMatch != null) merchant = merchantMatch.group(1)?.trim();
    }
    return baseline.copyWith(merchant: merchant);
  }
}

class IciciParser extends BankParserOverride {
  @override
  ParsedSms applyOverride(ParsedSms baseline) {
    final cleanBody = baseline.rawSms.replaceAll('\n', ' ').replaceAll('\r', ' ');
    final isCredit = baseline.isCredit == true;
    String? merchant = baseline.merchant;
    
    if (!isCredit) {
      final merchantMatch = RegExp(r';\s*(.*?)\s+credited\.', caseSensitive: false).firstMatch(cleanBody);
      if (merchantMatch != null) merchant = merchantMatch.group(1)?.trim();
    } else {
      final merchantMatch = RegExp(r'Info\s*(.*?)\.\s*Available', caseSensitive: false).firstMatch(cleanBody);
      if (merchantMatch != null) merchant = merchantMatch.group(1)?.trim();
    }
    return baseline.copyWith(merchant: merchant);
  }
}

class DefaultParser extends BankParserOverride {
  @override
  ParsedSms applyOverride(ParsedSms baseline) {
    return baseline;
  }
}
