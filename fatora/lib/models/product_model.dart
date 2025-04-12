class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double? cost;
  final String? unit; // e.g., piece, kg, hour
  final int? quantity;
  final String? sku; // Stock Keeping Unit
  final bool isActive;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.cost,
    this.unit,
    this.quantity,
    this.sku,
    this.isActive = true,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      cost: json['cost'] != null ? (json['cost']).toDouble() : null,
      unit: json['unit'],
      quantity: json['quantity'],
      sku: json['sku'],
      isActive: json['isActive'] ?? true,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'cost': cost,
      'unit': unit,
      'quantity': quantity,
      'sku': sku,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? cost,
    String? unit,
    int? quantity,
    String? sku,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      sku: sku ?? this.sku,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
