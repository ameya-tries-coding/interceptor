import 'package:get_it/get_it.dart';
import '../../services/transaction_repository.dart';
import '../../services/upi_payment_service.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<TransactionRepository>(
    () => SharedPreferencesTransactionRepository(),
  );
  locator.registerLazySingleton<UpiPaymentService>(
    () => UpiPaymentService(),
  );
}
