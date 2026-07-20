import 'package:get_it/get_it.dart';
import '../../services/transaction_repository.dart';
import '../../services/upi_payment_service.dart';
import '../../services/transaction_matching_service.dart';
import '../../services/transaction_matching_service_impl.dart';
import '../../services/sms_integration_service.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<TransactionRepository>(
    () => SharedPreferencesTransactionRepository(),
  );
  locator.registerLazySingleton<TransactionMatchingService>(
    () => TransactionMatchingServiceImpl(locator<TransactionRepository>()),
  );
  locator.registerLazySingleton<SmsIntegrationService>(
    () => SmsIntegrationService(),
  );
  locator.registerLazySingleton<UpiPaymentService>(
    () => UpiPaymentService(),
  );
}
