import 'package:sms_ingress/sms_ingress.dart';
import 'transaction_matching_service.dart';
import '../core/utils/service_locator.dart';
import 'package:flutter/foundation.dart';

class SmsIntegrationService {
  late final SmsIngress _smsIngress;

  SmsIntegrationService() {
    _smsIngress = SmsIngress();
  }

  Future<void> initialize() async {
    final permissionsGranted = await _smsIngress.requestPermissions();
    if (!permissionsGranted) {
      debugPrint('SMS permissions denied. SMS parsing will not work.');
      return;
    }

    await _smsIngress.initializeStorage();
    _smsIngress.startListening();

    _smsIngress.onParsedSms.listen((parsedSms) async {
      debugPrint('New Parsed SMS received: ${parsedSms.amount} from ${parsedSms.merchant}');
      
      final matchingService = locator<TransactionMatchingService>();
      await matchingService.reconcileTransaction(parsedSms);
    });
  }

  void dispose() {
    _smsIngress.dispose();
  }
}
