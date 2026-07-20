import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class UpiResponse {
  final String? status;
  final String? approvalRefNo;
  final String? txnRef;
  final String? transactionId;
  final String? responseCode;
  
  UpiResponse({
    this.status,
    this.approvalRefNo,
    this.txnRef,
    this.transactionId,
    this.responseCode,
  });
}

class UpiPaymentService {
  static const MethodChannel _channel = MethodChannel('com.example.intercept/share');

  Future<UpiResponse> generateAndShareQR(String upiUri) async {
    try {
      final painter = QrPainter(
        data: upiUri,
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

      // Directly share the image to GPay using MethodChannel
      await _channel.invokeMethod('shareToGPay', {'imagePath': file.path});
      
      // Since this is a fire-and-forget image share, we don't receive a true callback.
      // We return 'SUBMITTED' so the transaction screen knows it was launched successfully.
      return UpiResponse(status: 'SUBMITTED');
    } catch (e) {
      return UpiResponse(status: 'FAILURE');
    }
  }
}
