class OrderItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final String? options;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.options,
  });

  double get totalPrice => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] as String? ?? json['productName'] as String? ?? 'Item',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0.0,
      options: json['options'] as String? ?? json['specialInstructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
    if (options != null) 'options': options,
  };
}
