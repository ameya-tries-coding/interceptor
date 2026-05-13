import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPI Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EA),
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
          background: const Color(0xFF121212),
        ),
        fontFamily: 'Inter',
      ),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        // Stop scanning to prevent multiple triggers
        setState(() {
          _isScanning = false;
        });
        
        _processQrCode(code);
      }
    }
  }

  void _processQrCode(String code) {
    String? payeeAddress;
    String? payeeName;

    try {
      if (code.toLowerCase().startsWith('upi://pay')) {
        final uri = Uri.parse(code);
        payeeAddress = uri.queryParameters['pa'];
        payeeName = uri.queryParameters['pn'] ?? 'Unknown Payee';
      } else if (code.contains('@')) {
        payeeAddress = code.trim();
        payeeName = 'Unknown Payee';
      } else {
        throw Exception('Invalid QR code format');
      }

      if (payeeAddress == null || payeeAddress.isEmpty) {
        throw Exception('UPI ID not found in QR code');
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentDetailsScreen(
            payeeAddress: payeeAddress!,
            payeeName: payeeName!,
          ),
        ),
      ).then((_) {
        // Resume scanning when coming back
        setState(() {
          _isScanning = true;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.redAccent,
        ),
      );
      // Resume scanning after error
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isScanning = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan to Pay', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TransactionsScreen()),
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedContainer(
                      duration: const Duration(seconds: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.0),
                            Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Align QR code within frame',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentDetailsScreen extends StatefulWidget {
  final String payeeAddress;
  final String payeeName;

  const PaymentDetailsScreen({
    super.key,
    required this.payeeAddress,
    required this.payeeName,
  });

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final TextEditingController _amountController = TextEditingController();
  final List<String> _categories = ['Food', 'Travel', 'Groceries', 'Shopping', 'Utilities', 'Entertainment', 'Other'];
  String? _selectedCategory;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    final amount = _amountController.text.trim();
    if (amount.isEmpty || double.tryParse(amount) == null || double.parse(amount) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Construct UPI URI
    final String note = _selectedCategory!;
    final Uri upiUri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': widget.payeeAddress,
        'pn': widget.payeeName,
        'am': amount,
        'cu': 'INR',
        'tn': note,
      },
    );

    // Save transaction to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> transactions = prefs.getStringList('transactions') ?? [];
      final newTx = {
        'payeeName': widget.payeeName,
        'payeeAddress': widget.payeeAddress,
        'amount': amount,
        'category': _selectedCategory,
        'date': DateTime.now().toIso8601String(),
      };
      transactions.add(jsonEncode(newTx));
      await prefs.setStringList('transactions', transactions);
    } catch (e) {
      debugPrint('Failed to save transaction: $e');
    }

    // Generate and share the QR code directly via intents
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating payment QR code...')),
        );
      }

      final painter = QrPainter(
        data: upiUri.toString(),
        version: QrVersions.auto,
        gapless: false,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );

      final picData = await painter.toImageData(2048, format: ui.ImageByteFormat.png);
      if (picData == null) throw Exception('Failed to generate QR code image');

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/upi_qr.png');
      await file.writeAsBytes(picData.buffer.asUint8List());

      // Share via intents using share_plus
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Scan to pay to ${widget.payeeName}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share QR: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payee Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paying to',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.payeeName,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.payeeAddress,
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Amount Input
              const Text(
                'Amount',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(fontSize: 32, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                ),
              ),
              const SizedBox(height: 40),

              // Categories
              const Text(
                'Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 60),

              // Pay Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Proceed to Pay',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> txStrings = prefs.getStringList('transactions') ?? [];
    setState(() {
      _transactions = txStrings.map((s) => jsonDecode(s) as Map<String, dynamic>).toList().reversed.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: _transactions.isEmpty
          ? const Center(child: Text('No transactions found'))
          : ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                final date = DateTime.parse(tx['date']);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.payment, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  title: Text(tx['payeeName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${tx['category']} • ${date.day}/${date.month}/${date.year}'),
                  trailing: Text('₹ ${tx['amount']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                );
              },
            ),
    );
  }
}
