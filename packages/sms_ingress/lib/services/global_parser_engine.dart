import '../models/parsed_sms.dart';
import 'transaction_classifier.dart';
import 'merchant_cleaner.dart';
import 'extractors/amount_extractor.dart';
import 'extractors/account_extractor.dart';
import 'extractors/reference_extractor.dart';
import 'extractors/merchant_extractor.dart';
import 'extractors/date_extractor.dart';

class GlobalParserEngine {
  static ParsedSms? extractBaseline(int id, String sender, String body, DateTime receivedTime) {
    if (!TransactionClassifier.isTransactionMessage(body)) return null;

    final direction = TransactionClassifier.detectDirection(body);
    final isCredit = direction == TransactionDirection.income;

    final amount = AmountExtractor.extract(body);
    final account = AccountExtractor.extract(body);
    final reference = ReferenceExtractor.extract(body);
    final date = DateExtractor.extract(body);
    
    final rawMerchant = MerchantExtractor.extract(body, isCredit);
    final merchant = MerchantCleaner.clean(rawMerchant);

    return ParsedSms(
      smsId: id,
      rawSms: body,
      sender: sender,
      amount: amount,
      accountLastDigits: account,
      merchant: merchant,
      transactionDate: date,
      smsReceivedTime: receivedTime,
      upiReference: reference,
      isCredit: direction == TransactionDirection.unknown ? null : isCredit,
    );
  }
}
