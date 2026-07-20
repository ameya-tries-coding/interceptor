import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../payments/payment_details_screen.dart';

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
    String? merchantCode;

    try {
      if (code.toLowerCase().startsWith('upi://pay')) {
        final uri = Uri.parse(code);
        payeeAddress = uri.queryParameters['pa'];
        payeeName = uri.queryParameters['pn'] ?? 'Unknown Payee';
        merchantCode = uri.queryParameters['mc'];
      } else if (code.contains('@')) {
        payeeAddress = code.trim();
        payeeName = 'Unknown Payee';
      } else {
        throw Exception('Invalid QR code format');
      }

      if (payeeAddress == null || payeeAddress.isEmpty) {
        throw Exception('UPI ID not found in QR code');
      }

      // Pause camera to prevent it from holding onto old frames
      cameraController.stop();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentDetailsScreen(
            payeeAddress: payeeAddress!,
            payeeName: payeeName!,
            merchantCode: merchantCode,
          ),
        ),
      ).then((_) {
        if (mounted) {
          // Wait a second before turning the camera back on to avoid scanning the exact same code
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              cameraController.start();
              setState(() {
                _isScanning = true;
              });
            }
          });
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
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
