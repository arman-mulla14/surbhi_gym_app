class Payment {
  final String id; 
  final String memberId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod; // Cash, UPI, Other
  final String? notes;

  Payment({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      memberId: map['memberId'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['paymentDate'] as String),
      paymentMethod: map['paymentMethod'] as String,
      notes: map['notes'] as String?,
    );
  }
}
