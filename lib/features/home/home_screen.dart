import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_repository.dart';
import '../../core/utils/service_locator.dart';
import '../scanner/scanner_screen.dart';
import '../transactions/transactions_screen.dart';
import '../transactions/uncategorized_transactions_screen.dart';
import 'package:sms_ingress/sms_ingress.dart';
import 'dart:async';
import '../../services/sms_integration_service.dart';
import '../../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _uncategorizedCount = 0;
  StreamSubscription? _smsSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadUncategorizedCount();
    
    _smsSubscription = locator<SmsIntegrationService>()
        .onReconciliationComplete
        .listen((_) {
      if (mounted) {
        _loadUncategorizedCount();
      }
    });
  }

  @override
  void dispose() {
    _smsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.sms.status;
    if (!status.isGranted) {
      await Permission.sms.request();
    }
  }

  Future<void> _loadUncategorizedCount() async {
    final repository = locator<TransactionRepository>();
    final transactions = await repository.getAllTransactions();
    
    int count = 0;
    for (var txn in transactions) {
      if (txn.category == 'Uncategorized' && txn.source == TransactionSource.sms) {
        count++;
      }
    }
    
    setState(() {
      _uncategorizedCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interceptor'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, _) {
              final isDark = currentMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_uncategorizedCount > 0)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UncategorizedTransactionsScreen(),
                    ),
                  ).then((_) => _loadUncategorizedCount());
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$_uncategorizedCount Uncategorized Transactions',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.amber, size: 16),
                    ],
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScannerScreen()),
                ).then((_) => _loadUncategorizedCount());
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner),
                  SizedBox(width: 12),
                  Text('Scan QR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TransactionsScreen()),
                ).then((_) => _loadUncategorizedCount());
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt),
                  SizedBox(width: 12),
                  Text('See Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SmsDemoScreen()),
                );
              },
              child: const Text('Raw SMS Parsed Data'),
            ),
          ],
        ),
      ),
    );
  }
}
