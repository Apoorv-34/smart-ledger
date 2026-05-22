class LedgerTransaction {
  final int? id;
  final int customerId;
  final String itemDetails;
  final double amount;
  final String type; // 'CREDIT' or 'PAYMENT'
  final String date;

  LedgerTransaction({
    this.id,
    required this.customerId,
    required this.itemDetails,
    required this.amount,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'item_details': itemDetails,
      'amount': amount,
      'type': type,
      'date': date,
    };
  }

  factory LedgerTransaction.fromMap(Map<String, dynamic> map) {
    return LedgerTransaction(
      id: map['id'],
      customerId: map['customer_id'],
      itemDetails: map['item_details'],
      amount: (map['amount'] as num).toDouble(),
      type: map['type'],
      date: map['date'],
    );
  }
}
