class PaymentMethod {
  final String id;
  final String userId;
  final String type; // 'bank', 'nequi', 'daviplata', etc.
  final String accountNumber;
  final String accountHolder;
  final String bankName;
  final bool isDefault;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.accountNumber,
    required this.accountHolder,
    required this.bankName,
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
      'bankName': bankName,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'],
      userId: map['userId'],
      type: map['type'],
      accountNumber: map['accountNumber'],
      accountHolder: map['accountHolder'],
      bankName: map['bankName'],
      isDefault: map['isDefault'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
} 