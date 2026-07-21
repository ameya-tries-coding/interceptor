import 'package:sms_ingress/sms_ingress.dart';
import '../models/transaction_model.dart';

/// Service interface for future SMS matching integration.
/// This prepares the architecture for reconciling UPI intents with 
/// banking SMS messages based on approvalRefNo/RRN.
abstract class TransactionMatchingService {
  /// Links an SMS object to an existing transaction.
  Future<bool> linkSmsToTransaction({
    required String smsId,
    required String localTransactionId,
  });

  /// Finds potential transaction matches for an incoming parsed SMS.
  Future<List<TransactionModel>> findPotentialMatches({
    required double amount,
    required String approvalRefNo,
  });

  /// Automatically reconciles transactions if a strong deduplication key match (approvalRefNo) is found.
  Future<void> reconcileTransaction(ParsedSms parsedSmsData);
}
