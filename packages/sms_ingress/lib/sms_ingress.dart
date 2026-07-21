library sms_ingress;

import 'dart:async';
import 'dart:ui';
import 'dart:isolate';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

import 'models/parsed_sms.dart';
import 'services/sms_parser.dart';
import 'services/sms_storage.dart';

export 'models/parsed_sms.dart';
export 'screens/sms_demo_screen.dart';

const String _isolateName = "sms_ingress_background_port";

@pragma('vm:entry-point')
void onBackgroundMessage(SmsMessage message) async {
  final id = message.id ?? message.hashCode;
  final sender = message.address ?? 'Unknown';
  final body = message.body ?? '';
  final date = message.date;
  final receivedTime = date != null ? DateTime.fromMillisecondsSinceEpoch(date) : DateTime.now();

  // Parse and save directly in background
  final parsed = SmsParser.parse(id, sender, body, receivedTime);
  if (parsed != null) {
    await SmsStorage.saveMessage(parsed);
  }

  // Ping foreground UI if it's active
  final SendPort? sendPort = IsolateNameServer.lookupPortByName(_isolateName);
  if (sendPort != null) {
    sendPort.send({
      'id': id,
      'address': sender,
      'body': body,
      'date': date,
    });
  }
}

class SmsIngress {
  static final SmsIngress _instance = SmsIngress._internal();
  factory SmsIngress() => _instance;
  SmsIngress._internal();

  final Telephony _telephony = Telephony.instance;
  final Set<int> _parsedSmsIds = {};
  bool _isListening = false;
  
  final StreamController<ParsedSms> _onParsedSmsController = StreamController<ParsedSms>.broadcast();
  Stream<ParsedSms> get onParsedSms => _onParsedSmsController.stream;

  final List<ParsedSms> _memoryStorage = [];
  List<ParsedSms> get parsedMessages => List.unmodifiable(_memoryStorage);

  final ReceivePort _receivePort = ReceivePort();

  Future<void> initializeStorage() async {
    final history = await SmsStorage.loadMessages();
    for (var sms in history) {
      if (!_parsedSmsIds.contains(sms.smsId)) {
        _parsedSmsIds.add(sms.smsId);
        _memoryStorage.add(sms);
      }
    }
  }

  Future<bool> requestPermissions() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  void startListening() {
    if (_isListening) return;
    _isListening = true;

    IsolateNameServer.removePortNameMapping(_isolateName);
    IsolateNameServer.registerPortWithName(_receivePort.sendPort, _isolateName);
    
    _receivePort.listen((dynamic data) {
      if (data is Map) {
        _processRawSms(
          data['id'] as int,
          data['address'] as String,
          data['body'] as String,
          data['date'] as int?,
        );
      }
    });

    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        _processRawSms(
          message.id ?? message.hashCode, 
          message.address ?? 'Unknown', 
          message.body ?? '', 
          message.date
        );
      },
      onBackgroundMessage: onBackgroundMessage,
      listenInBackground: true,
    );
  }

  void _processRawSms(int id, String sender, String body, int? date) async {
    if (_parsedSmsIds.contains(id)) return;
    
    print("DEBUG INGRESS: Received SMS from $sender -> Body: $body");
    
    final receivedTime = date != null 
        ? DateTime.fromMillisecondsSinceEpoch(date) 
        : DateTime.now();

    final parsed = SmsParser.parse(id, sender, body, receivedTime);
    if (parsed != null) {
      _parsedSmsIds.add(id);
      _memoryStorage.add(parsed);
      _onParsedSmsController.add(parsed);
      await SmsStorage.saveMessage(parsed); // Save foreground hits too
    }
  }

  void dispose() {
    IsolateNameServer.removePortNameMapping(_isolateName);
    _receivePort.close();
    _onParsedSmsController.close();
  }
}
