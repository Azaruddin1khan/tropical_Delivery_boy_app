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
}
