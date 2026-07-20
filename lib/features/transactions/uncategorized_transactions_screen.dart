import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_repository.dart';
import '../../core/utils/service_locator.dart';

class UncategorizedTransactionsScreen extends StatefulWidget {
  const UncategorizedTransactionsScreen({super.key});

  @override
  State<UncategorizedTransactionsScreen> createState() => _UncategorizedTransactionsScreenState();
}

class _UncategorizedTransactionsScreenState extends State<UncategorizedTransactionsScreen> {
  final TransactionRepository _repository = locator<TransactionRepository>();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  
  final PageController _pageController = PageController();

  final TextEditingController _payeeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedCategory = 'Food';

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Groceries',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final all = await _repository.getAllTransactions();
    setState(() {
      _transactions = all
          .where((t) => t.category == 'Uncategorized' && t.source == TransactionSource.sms)
          .toList();
      _isLoading = false;
      if (_transactions.isNotEmpty) {
        _updateControllers(0);
      }
    });
  }

  void _updateControllers(int index) {
    if (index < _transactions.length) {
      _payeeController.text = _transactions[index].payeeName;
      _noteController.clear();
      _selectedCategory = 'Food';
    }
  }

  void _saveCurrentTransaction(int index) async {
    final txn = _transactions[index];
    final updated = txn.copyWith(
      payeeName: _payeeController.text,
      category: _selectedCategory,
      note: _noteController.text,
    );

    await _repository.updateTransaction(updated);

    if (index + 1 < _transactions.length) {
      _updateControllers(index + 1);
      _pageController.animateToPage(
        index + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_transactions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Uncategorized')),
        body: const Center(child: Text('All caught up!')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorize SMS'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disables manual swiping
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final txn = _transactions[index];
          
          return Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Transaction ${index + 1} of ${_transactions.length}',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      '₹${txn.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Paid on ${txn.createdAt.toLocal().toString().split('.')[0]}',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Payee Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _payeeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = cat);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('Note (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'What was this for?',
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (txn.rawSms != null) ...[
                    const Text('Original SMS', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        txn.rawSms!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _saveCurrentTransaction(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Save & Next', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
