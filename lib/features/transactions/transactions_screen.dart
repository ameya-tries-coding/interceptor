import 'package:flutter/material.dart';
import '../../core/utils/service_locator.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_repository.dart';
import '../../services/sms_integration_service.dart';
import 'transaction_details_screen.dart';
import 'dart:async';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  StreamSubscription? _smsSubscription;

  final _txRepository = locator<TransactionRepository>();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    
    _smsSubscription = locator<SmsIntegrationService>()
        .onReconciliationComplete
        .listen((_) {
      if (mounted) {
        _loadTransactions();
      }
    });
  }

  @override
  void dispose() {
    _smsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final txList = await _txRepository.getAllTransactions();
    setState(() {
      _transactions = txList;
      _isLoading = false;
    });
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success: return Colors.greenAccent;
      case TransactionStatus.failed: return Colors.redAccent;
      case TransactionStatus.pending: return Colors.orangeAccent;
      case TransactionStatus.cancelled: return Colors.grey;
    }
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    double netFlow = 0;
    for (var tx in _transactions) {
      if (tx.createdAt.month == now.month && tx.createdAt.year == now.year && tx.transactionStatus == TransactionStatus.success) {
        if (tx.isCredit) {
          netFlow += tx.amount;
        } else {
          netFlow -= tx.amount;
        }
      }
    }

    final isPositive = netFlow >= 0;
    final formattedFlow = '${isPositive ? '+' : '-'} ₹${netFlow.abs().toStringAsFixed(2)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _transactions.isEmpty
          ? const Center(child: Text('No transactions found'))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${now.year}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(_getMonthName(now.month), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        formattedFlow,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.greenAccent : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final tx = _transactions[index];
                      final date = tx.createdAt;
                      
                      final amountString = tx.isCredit 
                          ? '+ ₹${tx.amount.toStringAsFixed(2)}' 
                          : '₹${tx.amount.toStringAsFixed(2)}';
                      
                      final amountColor = tx.isCredit ? Colors.greenAccent : Colors.white;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(Icons.payment, color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                        title: Text(tx.payeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${tx.category} • ${date.day}/${date.month}/${date.year}'),
                            if (tx.note.isNotEmpty) Text('Note: ${tx.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
                            Text('Status: ${tx.transactionStatus.name}', style: TextStyle(color: _getStatusColor(tx.transactionStatus))),
                            if (tx.txnRef != null) Text('Ref: ${tx.txnRef}', style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                        trailing: Text(amountString, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: amountColor)),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionDetailsScreen(transaction: tx),
                            ),
                          ).then((_) => _loadTransactions());
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
