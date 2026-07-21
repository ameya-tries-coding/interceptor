class ParsedSms {
  final int smsId;
  final String rawSms;
  final String sender;
  final double? amount;
  final String? accountLastDigits;
  final String? merchant;
  final String? transactionDate;
  final DateTime? smsReceivedTime;
  final String? upiReference;
  final String? tag;
  final bool? isCredit;

  ParsedSms({
    required this.smsId,
    required this.rawSms,
    required this.sender,
    this.amount,
    this.accountLastDigits,
    this.merchant,
    this.transactionDate,
    this.smsReceivedTime,
    this.upiReference,
    this.tag,
    this.isCredit,
  });

  ParsedSms copyWith({
    int? smsId,
    String? rawSms,
    String? sender,
    double? amount,
    String? accountLastDigits,
    String? merchant,
    String? transactionDate,
    DateTime? smsReceivedTime,
    String? upiReference,
    String? tag,
    bool? isCredit,
  }) {
    return ParsedSms(
      smsId: smsId ?? this.smsId,
      rawSms: rawSms ?? this.rawSms,
      sender: sender ?? this.sender,
      amount: amount ?? this.amount,
      accountLastDigits: accountLastDigits ?? this.accountLastDigits,
      merchant: merchant ?? this.merchant,
      transactionDate: transactionDate ?? this.transactionDate,
      smsReceivedTime: smsReceivedTime ?? this.smsReceivedTime,
      upiReference: upiReference ?? this.upiReference,
      tag: tag ?? this.tag,
      isCredit: isCredit ?? this.isCredit,
    );
  }

  Map<String, dynamic> toJson() => {
    'smsId': smsId,
    'rawSms': rawSms,
    'sender': sender,
    'amount': amount,
    'accountLastDigits': accountLastDigits,
    'merchant': merchant,
    'transactionDate': transactionDate,
    'smsReceivedTime': smsReceivedTime?.toIso8601String(),
    'upiReference': upiReference,
    'tag': tag,
    'isCredit': isCredit,
  };

  factory ParsedSms.fromJson(Map<String, dynamic> json) => ParsedSms(
    smsId: json['smsId'] as int,
    rawSms: json['rawSms'] as String,
    sender: json['sender'] as String,
    amount: (json['amount'] as num?)?.toDouble(),
    accountLastDigits: json['accountLastDigits'] as String?,
    merchant: json['merchant'] as String?,
    transactionDate: json['transactionDate'] as String?,
    smsReceivedTime: json['smsReceivedTime'] != null ? DateTime.parse(json['smsReceivedTime'] as String) : null,
    upiReference: json['upiReference'] as String?,
    tag: json['tag'] as String?,
    isCredit: json['isCredit'] as bool?,
  );
}
