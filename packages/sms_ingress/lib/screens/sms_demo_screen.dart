import 'package:flutter/material.dart';
import '../sms_ingress.dart';

class SmsDemoScreen extends StatefulWidget {
  const SmsDemoScreen({super.key});

  @override
  State<SmsDemoScreen> createState() => _SmsDemoScreenState();
}

class _SmsDemoScreenState extends State<SmsDemoScreen> {
  final SmsIngress _ingress = SmsIngress();
  String _status = "Initializing...";

  @override
  void initState() {
    super.initState();
    _initIngress();
  }

  Future<void> _initIngress() async {
    await _ingress.initializeStorage();
    if (mounted) {
      setState(() {});
    }

    final granted = await _ingress.requestPermissions();
    if (granted) {
      _ingress.startListening();
      if (mounted) {
        setState(() {
          _status = "Listening for incoming SMS...";
        });
      }
      _ingress.onParsedSms.listen((_) {
        if (mounted) {
          setState(() {}); // Rebuild to show new messages
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _status = "SMS Permission denied.";
        });
      }
    }
  }

  @override
  void dispose() {
    _ingress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _ingress.parsedMessages.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('SMS Ingress Prototype')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_status, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final sms = messages[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sender: ${sms.sender}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (sms.isCredit != null)
                              Icon(
                                sms.isCredit! ? Icons.arrow_downward : Icons.arrow_upward,
                                color: sms.isCredit! ? Colors.green : Colors.red,
                                size: 24,
                              ),
                          ],
                        ),
                        Text('Tag: ${sms.tag}'),
                        Text('Amount: ${sms.amount}'),
                        Text('Account: ${sms.accountLastDigits}'),
                        Text('Merchant: ${sms.merchant}'),
                        Text('Date: ${sms.transactionDate}'),
                        Text('UPI Ref: ${sms.upiReference}'),
                        Text('Received: ${sms.smsReceivedTime}'),
                        const Divider(),
                        Text('Raw: ${sms.rawSms}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
