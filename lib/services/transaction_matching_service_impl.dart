import 'package:sms_ingress/sms_ingress.dart';
import 'package:collection/collection.dart';
import '../models/transaction_model.dart';
import 'transaction_repository.dart';
import 'transaction_matching_service.dart';

class TransactionMatchingServiceImpl implements TransactionMatchingService {
  final TransactionRepository _repository;

  TransactionMatchingServiceImpl(this._repository);

  @override
  Future<bool> linkSmsToTransaction({
    required String smsId,
    required String localTransactionId,
  }) async {
    final transactions = await _repository.getAllTransactions();
    final index = transactions.indexWhere((t) => t.localTransactionId == localTransactionId);
    
    if (index != -1) {
      final txn = transactions[index];
      final updatedTxn = txn.copyWith(
        smsId: smsId,
        smsLinked: true,
      );
      await _repository.updateTransaction(updatedTxn);
      return true;
    }
    return false;
  }

  @override
  Future<List<TransactionModel>> findPotentialMatches({
    required double amount,
    required String approvalRefNo,
  }) async {
    final transactions = await _repository.getAllTransactions();
    return transactions.where((t) => 
      t.transactionStatus == TransactionStatus.pending && 
      t.amount == amount
    ).toList();
  }

  @override
  Future<void> reconcileTransaction(ParsedSms parsedSmsData) async {
    if (parsedSmsData.isCredit == true) return; // Only care about debits for now
    if (parsedSmsData.amount == null) return;

    final transactions = await _repository.getAllTransactions();
    
    // Look for pending interceptor payments
    final pendingTransactions = transactions.where((t) => 
      t.transactionStatus == TransactionStatus.pending && 
      t.source == TransactionSource.interceptor
    ).toList();

    // Find match based on amount and time (within 10 minutes)
    final match = pendingTransactions.firstWhereOrNull((txn) {
      final isSameAmount = txn.amount == parsedSmsData.amount;
      final smsTime = parsedSmsData.smsReceivedTime ?? DateTime.now();
      final timeDifference = smsTime.difference(txn.createdAt).inMinutes.abs();
      final isWithinTimeWindow = timeDifference <= 10;
      
      return isSameAmount && isWithinTimeWindow;
    });

    if (match != null) {
      final updatedTxn = match.copyWith(
        transactionStatus: TransactionStatus.success,
        txnRef: parsedSmsData.upiReference,
        smsId: parsedSmsData.smsId.toString(),
        smsLinked: true,
        rawSms: parsedSmsData.rawSms,
        accountLastDigits: parsedSmsData.accountLastDigits,
        sender: parsedSmsData.sender,
      );
      await _repository.updateTransaction(updatedTxn);
    } else {
      // No match found - create new SMS transaction (Uncategorized)
      final newSmsTxn = TransactionModel(
        payeeName: parsedSmsData.merchant ?? 'Unknown Merchant',
        payeeAddress: 'sms_extracted',
        amount: parsedSmsData.amount!,
        category: 'Uncategorized',
        source: TransactionSource.sms,
        transactionStatus: TransactionStatus.success,
        txnRef: parsedSmsData.upiReference,
        smsLinked: true,
        rawSms: parsedSmsData.rawSms,
        accountLastDigits: parsedSmsData.accountLastDigits,
        sender: parsedSmsData.sender,
        createdAt: parsedSmsData.smsReceivedTime ?? DateTime.now(),
      );
      await _repository.saveTransaction(newSmsTxn);
    }
  }
}
