import 'order_item.dart';

enum DeliveryOrderStatus {
  assigned('Assigned', 'Order waiting to be dispatched'),
  outForDelivery('Out for Delivery', 'Courier is en route to customer'),
  delivered('Delivered', 'Delivered to customer address'),
  pickedUp('Picked Up', 'Order handed over to customer at pickup counter');

  final String label;
  final String description;
  const DeliveryOrderStatus(this.label, this.description);
}

class DeliveryOrder {
  final String id;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final List<OrderItem> items;
  final DateTime orderTime;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double totalAmount;
  final String paymentMethod; // e.g. "Cash on Delivery", "Credit Card", "Apple Pay", "Counter Pickup"
  final bool isPaid;
  final DeliveryOrderStatus status;
  final String barcodeCode;
  final String qrCode;
  final String? deliveryNotes;
  final String orderType; // 'delivery' or 'pickup'
  final DateTime? deliveredAt;

  const DeliveryOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.orderTime,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.totalAmount,
    required this.paymentMethod,
    required this.isPaid,
    required this.status,
    required this.barcodeCode,
    required this.qrCode,
    this.deliveryNotes,
    this.orderType = 'delivery',
    this.deliveredAt,
  });

  bool get isCashOnDelivery =>
      paymentMethod.toLowerCase().contains('cash') && orderType == 'delivery';

  bool get requiresCashCollection => !isPaid;

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  DeliveryOrder copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    List<OrderItem>? items,
    DateTime? orderTime,
    double? subtotal,
    double? deliveryFee,
    double? tax,
    double? totalAmount,
    String? paymentMethod,
    bool? isPaid,
    DeliveryOrderStatus? status,
    String? barcodeCode,
    String? qrCode,
    String? deliveryNotes,
    String? orderType,
    DateTime? deliveredAt,
  }) {
    return DeliveryOrder(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      orderTime: orderTime ?? this.orderTime,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tax: tax ?? this.tax,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      status: status ?? this.status,
      barcodeCode: barcodeCode ?? this.barcodeCode,
      qrCode: qrCode ?? this.qrCode,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      orderType: orderType ?? this.orderType,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}
