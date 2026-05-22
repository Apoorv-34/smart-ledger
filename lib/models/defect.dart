class Defect {
  final int? id;
  final String itemDetails;
  final int quantity;
  final String dateLogged;
  final String status; // 'PENDING' or 'RESOLVED'

  Defect({
    this.id,
    required this.itemDetails,
    required this.quantity,
    required this.dateLogged,
    this.status = 'PENDING',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_details': itemDetails,
      'quantity': quantity,
      'date_logged': dateLogged,
      'status': status,
    };
  }

  factory Defect.fromMap(Map<String, dynamic> map) {
    return Defect(
      id: map['id'],
      itemDetails: map['item_details'],
      quantity: map['quantity'],
      dateLogged: map['date_logged'],
      status: map['status'],
    );
  }
  
  Defect copyWith({
    int? id,
    String? itemDetails,
    int? quantity,
    String? dateLogged,
    String? status,
  }) {
    return Defect(
      id: id ?? this.id,
      itemDetails: itemDetails ?? this.itemDetails,
      quantity: quantity ?? this.quantity,
      dateLogged: dateLogged ?? this.dateLogged,
      status: status ?? this.status,
    );
  }
}
