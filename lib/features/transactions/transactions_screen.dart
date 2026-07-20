import 'package:flutter/material.dart';
import '../../core/utils/service_locator.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_repository.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  final _txRepository = locator<TransactionRepository>();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _transactions.isEmpty
          ? const Center(child: Text('No transactions found'))
          : ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                final date = tx.createdAt;
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
                  trailing: Text('₹ ${tx.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  isThreeLine: true,
                );
              },
            ),
    );
  }
}
