enum TransactionDirection { income, expense, unknown }

class TransactionClassifier {
  static bool isTransactionMessage(String message) {
    final bodyLower = message.toLowerCase();
    
    // Negative indicators: reject early
    if (bodyLower.contains('otp') ||
        bodyLower.contains('verification code') ||
        bodyLower.contains('offer') ||
        bodyLower.contains('discount') ||
        bodyLower.contains('bill generated') ||
        bodyLower.contains('statement generated') ||
        bodyLower.contains('e-statement') ||
        bodyLower.contains('mandate registered') ||
        bodyLower.contains('autopay activated') ||
        bodyLower.contains('payment request') ||
        bodyLower.contains('collect request') ||
        bodyLower.contains('due')) {
      return false;
    }

    // Default allow: If a message is from a transactional sender and 
    // lacks strong negative indicators, let the global engine attempt 
    // to extract an amount.
    return true;
  }

  static TransactionDirection detectDirection(String message) {
    final bodyLower = message.toLowerCase();
    
    final isIncome = bodyLower.contains('credited') || 
                     bodyLower.contains('received') || 
                     bodyLower.contains('refund') ||
                     bodyLower.contains('cr.') ||
                     bodyLower.contains('credit');
                     
    final isExpense = bodyLower.contains('debited') || 
                      bodyLower.contains('spent') || 
                      bodyLower.contains('paid') || 
                      bodyLower.contains('withdrawn') || 
                      bodyLower.contains('sent') ||
                      bodyLower.contains('dr.') ||
                      bodyLower.contains('debit');

    if (isIncome && !isExpense) return TransactionDirection.income;
    if (isExpense && !isIncome) return TransactionDirection.expense;
    
    if (isIncome && isExpense) {
      final incomePos = bodyLower.indexOf(RegExp(r'(credited|received|refund|cr\.|credit)'));
      final expensePos = bodyLower.indexOf(RegExp(r'(debited|spent|paid|withdrawn|sent|dr\.|debit)'));
      
      if (incomePos != -1 && expensePos != -1) {
        return incomePos < expensePos ? TransactionDirection.income : TransactionDirection.expense;
      }
    }
    
    return TransactionDirection.unknown;
  }
}
