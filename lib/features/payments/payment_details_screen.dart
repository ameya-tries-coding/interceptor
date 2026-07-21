import 'package:flutter/material.dart';
import '../../core/utils/service_locator.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_repository.dart';
import '../../services/upi_payment_service.dart';
import 'package:uuid/uuid.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final String payeeAddress;
  final String payeeName;
  final String? merchantCode;

  const PaymentDetailsScreen({
    super.key,
    required this.payeeAddress,
    required this.payeeName,
    this.merchantCode,
  });

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final List<String> _categories = ['Food', 'Travel', 'Groceries', 'Shopping', 'Utilities', 'Entertainment', 'Other'];
  String? _selectedCategory;
  bool _isProcessing = false;

  final _txRepository = locator<TransactionRepository>();
  final _upiService = locator<UpiPaymentService>();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || double.tryParse(amountText) == null || double.parse(amountText) <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (_selectedCategory == null) {
      _showError('Please select a category');
      return;
    }

    final double amount = double.parse(amountText);
    final String userNote = _noteController.text.trim();
    
    // Fallback to category if note is empty, else combine them or just use note.
    final String tnStr = userNote.isNotEmpty ? userNote : _selectedCategory!;
    
    // Generate custom transaction reference
    final String tr = 'TR${const Uuid().v4().replaceAll('-', '').substring(0, 10)}'.toUpperCase();

    // 1. Create Pending Transaction
    TransactionModel tx = TransactionModel(
      payeeName: widget.payeeName,
      payeeAddress: widget.payeeAddress,
      amount: amount,
      category: _selectedCategory!,
      note: userNote,
      transactionStatus: TransactionStatus.pending,
      txnRef: tr,
    );
    
    setState(() { _isProcessing = true; });
    await _txRepository.saveTransaction(tx);

    // 2. Launch UPI Intent
    final String noteEncoded = Uri.encodeQueryComponent(tnStr);
    final String payeeNameEncoded = Uri.encodeQueryComponent(widget.payeeName);
    
    // Build UPI URL dynamically to avoid fraud flags in P2P transfers
    String upiUrl = 'upi://pay?pa=${widget.payeeAddress}&pn=$payeeNameEncoded&am=$amountText&cu=INR&tn=$noteEncoded';
    
    if (widget.merchantCode != null && widget.merchantCode!.isNotEmpty) {
      upiUrl += '&mc=${widget.merchantCode}';
      upiUrl += '&tr=$tr'; // Only pass tracking ID for valid merchants
    }

    // 3. Update Transaction State to Pending
    tx = tx.copyWith(
      transactionStatus: TransactionStatus.pending,
    );
    await _txRepository.updateTransaction(tx);
    
    // 4. Generate QR and share to GPay directly from this screen
    await _upiService.generateAndShareQR(upiUrl);

    // Stop loading animation
    if (mounted) {
      setState(() { _isProcessing = false; });
      
      // Silently close this screen after a delay while the user is inside GPay.
      // This ensures that when they eventually press back from GPay, they land on a fresh scanner.
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isProcessing 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payee Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Paying to', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(widget.payeeName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(widget.payeeAddress, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  const Text('Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(fontSize: 32, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text('Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12, runSpacing: 12,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) => setState(() => _selectedCategory = selected ? category : null),
                        selectedColor: Theme.of(context).colorScheme.primary,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),

                  const Text('Note (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Add a note for this payment',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                  
                  const SizedBox(height: 60),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: const Text('Proceed to Pay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
