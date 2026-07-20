import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_repository.dart';
import '../../core/utils/service_locator.dart';
import 'package:intl/intl.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  late TransactionModel _transaction;
  final _repository = locator<TransactionRepository>();

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
  }

  void _markAsSuccess() async {
    final updated = _transaction.copyWith(transactionStatus: TransactionStatus.success);
    await _repository.updateTransaction(updated);
    setState(() {
      _transaction = updated;
    });
  }

  void _deleteTransaction() async {
    await _repository.deleteTransaction(_transaction.localTransactionId);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat("d MMM yyyy, h:mm a");
    final dateString = dateFormat.format(_transaction.createdAt.toLocal());
    
    final isSuccess = _transaction.transactionStatus == TransactionStatus.success;
    final isPending = _transaction.transactionStatus == TransactionStatus.pending;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteTransaction();
              } else if (value == 'success') {
                _markAsSuccess();
              }
            },
            itemBuilder: (context) => [
              if (isPending)
                const PopupMenuItem(
                  value: 'success',
                  child: Text('Mark as Success'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Transaction', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.brown.shade700,
              child: Text(
                _transaction.payeeName.isNotEmpty ? _transaction.payeeName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 28, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'To ${_transaction.payeeName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '₹${_transaction.amount.toStringAsFixed(2).replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "")}',
              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _transaction.category,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.access_time_filled,
                  color: isSuccess ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _transaction.transactionStatus.name[0].toUpperCase() + 
                  _transaction.transactionStatus.name.substring(1),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              dateString,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            if (isPending) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Did this transaction happen?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _deleteTransaction,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            child: const Text('No'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _markAsSuccess,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Yes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade800),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Icon(Icons.account_balance, color: Colors.blue.shade900, size: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _transaction.accountLastDigits != null 
                              ? 'Bank Account XX${_transaction.accountLastDigits}'
                              : 'Bank Account',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey.shade800, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('UPI transaction ID', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(_transaction.txnRef ?? 'Pending', style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        
                        Text('To: ${_transaction.payeeName}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(_transaction.payeeAddress, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        
                        if (_transaction.note.isNotEmpty) ...[
                          const Text('Note', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(_transaction.note, style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 16),
                        ],
                        
                        if (_transaction.rawSms != null) ...[
                          const Text('Raw SMS Data', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(_transaction.rawSms!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
