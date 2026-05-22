class InventoryItem {
  final int? id;
  final String brand;
  final String model;
  final String qualityGrade;
  final double wholesalePrice;
  final double retailPrice;
  final int stockCount;

  InventoryItem({
    this.id,
    required this.brand,
    required this.model,
    required this.qualityGrade,
    required this.wholesalePrice,
    required this.retailPrice,
    required this.stockCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'quality_grade': qualityGrade,
      'wholesale_price': wholesalePrice,
      'retail_price': retailPrice,
      'stock_count': stockCount,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      brand: map['brand'],
      model: map['model'],
      qualityGrade: map['quality_grade'],
      wholesalePrice: map['wholesale_price'],
      retailPrice: map['retail_price'],
      stockCount: map['stock_count'],
    );
  }

  InventoryItem copyWith({
    int? id,
    String? brand,
    String? model,
    String? qualityGrade,
    double? wholesalePrice,
    double? retailPrice,
    int? stockCount,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      retailPrice: retailPrice ?? this.retailPrice,
      stockCount: stockCount ?? this.stockCount,
    );
  }
}
