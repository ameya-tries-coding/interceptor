import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';

abstract class TransactionRepository {
  Future<void> saveTransaction(TransactionModel transaction);
  Future<List<TransactionModel>> getAllTransactions();
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String localTransactionId);
}

class SharedPreferencesTransactionRepository implements TransactionRepository {
  static const String _storageKey = 'transactions_v2';

  @override
  Future<void> saveTransaction(TransactionModel transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> transactions = prefs.getStringList(_storageKey) ?? [];
    transactions.add(jsonEncode(transaction.toJson()));
    await prefs.setStringList(_storageKey, transactions);
  }

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> txStrings = prefs.getStringList(_storageKey) ?? [];
    final List<TransactionModel> txList = txStrings
        .map((s) => TransactionModel.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    
    // Sort descending by date
    txList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return txList;
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> txStrings = prefs.getStringList(_storageKey) ?? [];
    
    List<TransactionModel> txList = txStrings
        .map((s) => TransactionModel.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();

    final index = txList.indexWhere((tx) => tx.localTransactionId == transaction.localTransactionId);
    if (index != -1) {
      txList[index] = transaction;
      final updatedStrings = txList.map((tx) => jsonEncode(tx.toJson())).toList();
      await prefs.setStringList(_storageKey, updatedStrings);
    } else {
      // If it doesn't exist, we save it
      await saveTransaction(transaction);
    }
  }

  @override
  Future<void> deleteTransaction(String localTransactionId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> txStrings = prefs.getStringList(_storageKey) ?? [];
    
    List<TransactionModel> txList = txStrings
        .map((s) => TransactionModel.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();

    txList.removeWhere((tx) => tx.localTransactionId == localTransactionId);
    
    final updatedStrings = txList.map((tx) => jsonEncode(tx.toJson())).toList();
    await prefs.setStringList(_storageKey, updatedStrings);
  }
}
