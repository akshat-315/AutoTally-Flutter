class ParsedSMS {
  final String direction;
  final int amount;
  final String bank;
  final String? accountLast4;
  final String? merchantRaw;
  final String? vpa;
  final String? upiRef;
  final DateTime? transactionDate;

  ParsedSMS({
    required this.direction,
    required this.amount,
    required this.bank,
    this.accountLast4,
    this.merchantRaw,
    this.vpa,
    this.upiRef,
    this.transactionDate,
  });
}
