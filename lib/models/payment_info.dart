class PaymentInfo {
  final String qrCodeUrl;
  final String bankCode;
  final String accountNumber;
  final String accountName;
  final double amount;
  final String content;
  final String note;

  PaymentInfo({
    required this.qrCodeUrl,
    required this.bankCode,
    required this.accountNumber,
    required this.accountName,
    required this.amount,
    required this.content,
    required this.note,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      qrCodeUrl: json['qrCodeUrl'],
      bankCode: json['bankCode'],
      accountNumber: json['accountNumber'],
      accountName: json['accountName'],
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      content: json['content'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qrCodeUrl': qrCodeUrl,
      'bankCode': bankCode,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'amount': amount,
      'content': content,
      'note': note,
    };
  }
}