import 'package:flutter_test/flutter_test.dart';
import 'package:sms_ingress/services/extractors/amount_extractor.dart';

void main() {
  group('AmountExtractor Tests', () {
    test('Extracts standard Rs amount', () {
      final amount = AmountExtractor.extract('Debited Rs 500.00 from account');
      expect(amount, 500.0);
    });

    test('Extracts INR amount', () {
      final amount = AmountExtractor.extract('INR 1,200.50 spent');
      expect(amount, 1200.5);
    });
  });
}
