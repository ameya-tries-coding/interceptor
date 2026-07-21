import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parsed_sms.dart';

class SmsStorage {
  static const String _storageKey = 'sms_ingress_parsed_messages';

  static Future<void> saveMessage(ParsedSms sms) async {
    final prefs = await SharedPreferences.getInstance();
    
    final List<String> existingRecords = prefs.getStringList(_storageKey) ?? [];
    
    // Deduplicate on read
    for (var record in existingRecords) {
      final decoded = jsonDecode(record);
      if (decoded['smsId'] == sms.smsId) {
        return; 
      }
    }
    
    existingRecords.add(jsonEncode(sms.toJson()));
    
    // Keep max 100 messages in prototype
    if (existingRecords.length > 100) {
      existingRecords.removeAt(0);
    }
    
    await prefs.setStringList(_storageKey, existingRecords);
  }

  static Future<List<ParsedSms>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existingRecords = prefs.getStringList(_storageKey) ?? [];
    
    return existingRecords.map((record) => ParsedSms.fromJson(jsonDecode(record))).toList();
  }
}
