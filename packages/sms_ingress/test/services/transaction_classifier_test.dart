import 'package:flutter_test/flutter_test.dart';
import 'package:sms_ingress/services/transaction_classifier.dart';

void main() {
  group('TransactionClassifier Tests', () {
    test('debit: Rs 500 passes (Implicit Transaction)', () {
      final result = TransactionClassifier.isTransactionMessage('debit: Rs 500');
      expect(result, isTrue);
    });

    test('UPI txn of Rs 500 passes (Implicit Transaction)', () {
      final result = TransactionClassifier.isTransactionMessage('UPI txn of Rs 500');
      expect(result, isTrue);
    });

    test('Card XX1234 used for Rs 500 passes (Implicit Transaction)', () {
      final result = TransactionClassifier.isTransactionMessage('Card XX1234 used for Rs 500');
      expect(result, isTrue);
    });

    test('OTP for Rs 500 fails (Negative Indicator)', () {
      final result = TransactionClassifier.isTransactionMessage('OTP for Rs 500 payment');
      expect(result, isFalse);
    });

    test('Bill generated for Rs 12000 fails (Negative Indicator)', () {
      final result = TransactionClassifier.isTransactionMessage('Your bill generated for Rs 12000 is ready');
      expect(result, isFalse);
    });

    test('Offer save Rs 500 fails (Negative Indicator)', () {
      final result = TransactionClassifier.isTransactionMessage('Special offer save Rs 500 on your next order');
      expect(result, isFalse);
    });
  });
}
