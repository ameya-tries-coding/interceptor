import 'package:uuid/uuid.dart';

enum TransactionStatus {
  pending,
  success,
  failed,
  cancelled
}

enum TransactionSource {
  interceptor,
  sms
}

class TransactionModel {
  final String localTransactionId;
  final String payeeName;
  final String payeeAddress;
  final double amount;
  final String category;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TransactionStatus transactionStatus;
  final TransactionSource source;
  final String? txnRef;
  final String? approvalRefNo;
  final String? transactionId;
  final String? responseCode;
  final String? smsId;
  final bool smsLinked;
  final String? rawSms;
  final String? accountLastDigits;
  final String? sender;
  final bool isCredit;

  TransactionModel({
    String? localTransactionId,
    required this.payeeName,
    required this.payeeAddress,
    required this.amount,
    required this.category,
    this.note = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.transactionStatus = TransactionStatus.pending,
    this.source = TransactionSource.interceptor,
    this.txnRef,
    this.approvalRefNo,
    this.transactionId,
    this.responseCode,
    this.smsId,
    this.smsLinked = false,
    this.rawSms,
    this.accountLastDigits,
    this.sender,
    this.isCredit = false,
  })  : localTransactionId = localTransactionId ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  TransactionModel copyWith({
    String? payeeName,
    String? payeeAddress,
    double? amount,
    String? category,
    String? note,
    DateTime? updatedAt,
    TransactionStatus? transactionStatus,
    TransactionSource? source,
    String? txnRef,
    String? approvalRefNo,
    String? transactionId,
    String? responseCode,
    String? smsId,
    bool? smsLinked,
    String? rawSms,
    String? accountLastDigits,
    String? sender,
    bool? isCredit,
  }) {
    return TransactionModel(
      localTransactionId: this.localTransactionId,
      payeeName: payeeName ?? this.payeeName,
      payeeAddress: payeeAddress ?? this.payeeAddress,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      transactionStatus: transactionStatus ?? this.transactionStatus,
      source: source ?? this.source,
      txnRef: txnRef ?? this.txnRef,
      approvalRefNo: approvalRefNo ?? this.approvalRefNo,
      transactionId: transactionId ?? this.transactionId,
      responseCode: responseCode ?? this.responseCode,
      smsId: smsId ?? this.smsId,
      smsLinked: smsLinked ?? this.smsLinked,
      rawSms: rawSms ?? this.rawSms,
      accountLastDigits: accountLastDigits ?? this.accountLastDigits,
      sender: sender ?? this.sender,
      isCredit: isCredit ?? this.isCredit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'localTransactionId': localTransactionId,
      'payeeName': payeeName,
      'payeeAddress': payeeAddress,
      'amount': amount,
      'category': category,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'transactionStatus': transactionStatus.name,
      'source': source.name,
      'txnRef': txnRef,
      'approvalRefNo': approvalRefNo,
      'transactionId': transactionId,
      'responseCode': responseCode,
      'smsId': smsId,
      'smsLinked': smsLinked,
      'rawSms': rawSms,
      'accountLastDigits': accountLastDigits,
      'sender': sender,
      'isCredit': isCredit,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      localTransactionId: json['localTransactionId'],
      payeeName: json['payeeName'],
      payeeAddress: json['payeeAddress'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      note: json['note'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      transactionStatus: TransactionStatus.values.firstWhere(
        (e) => e.name == json['transactionStatus'],
        orElse: () => TransactionStatus.pending,
      ),
      source: TransactionSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => TransactionSource.interceptor,
      ),
      txnRef: json['txnRef'],
      approvalRefNo: json['approvalRefNo'],
      transactionId: json['transactionId'],
      responseCode: json['responseCode'],
      smsId: json['smsId'],
      smsLinked: json['smsLinked'] ?? false,
      rawSms: json['rawSms'],
      accountLastDigits: json['accountLastDigits'],
      sender: json['sender'],
      isCredit: json['isCredit'] ?? false,
    );
  }
}
