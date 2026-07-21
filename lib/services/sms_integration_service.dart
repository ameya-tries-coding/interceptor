import 'dart:async';
import 'package:sms_ingress/sms_ingress.dart';
import 'transaction_matching_service.dart';
import '../core/utils/service_locator.dart';
import 'package:flutter/foundation.dart';

class SmsIntegrationService {
  late final SmsIngress _smsIngress;
  
  final StreamController<void> _onReconciliationCompleteController = StreamController<void>.broadcast();
  Stream<void> get onReconciliationComplete => _onReconciliationCompleteController.stream;

  SmsIntegrationService() {
    _smsIngress = SmsIngress();
  }

  Future<void> initialize() async {
    final permissionsGranted = await _smsIngress.requestPermissions();
    if (!permissionsGranted) {
      debugPrint('SMS permissions denied. SMS parsing will not work.');
      return;
    }

    await processBacklog();

    _smsIngress.startListening();

    _smsIngress.onParsedSms.listen((parsedSms) async {
      debugPrint('New Parsed SMS received: ${parsedSms.amount} from ${parsedSms.merchant}');
      
      final matchingService = locator<TransactionMatchingService>();
      await matchingService.reconcileTransaction(parsedSms);
      
      // Notify the UI that the database has been updated
      _onReconciliationCompleteController.add(null);
    });
  }

  Future<void> processBacklog() async {
    await _smsIngress.initializeStorage();
    
    // Process any messages that were received and saved in the background while the app was closed
    final matchingService = locator<TransactionMatchingService>();
    for (final parsedSms in _smsIngress.parsedMessages) {
      await matchingService.reconcileTransaction(parsedSms);
    }
    _onReconciliationCompleteController.add(null);
  }

  void dispose() {
    _smsIngress.dispose();
    _onReconciliationCompleteController.close();
  }
}
