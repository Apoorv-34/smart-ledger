class Customer {
  final int? id;
  final String name;
  final String phone;
  final double totalDue;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.totalDue = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'total_due': totalDue,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      totalDue: (map['total_due'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    double? totalDue,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      totalDue: totalDue ?? this.totalDue,
    );
  }
}
