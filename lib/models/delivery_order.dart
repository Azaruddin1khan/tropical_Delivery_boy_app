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
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? paymentCollectedMethod; // 'cash', 'credit_card', 'debit_card'

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
    this.assignedDriverId,
    this.assignedDriverName,
    this.paymentCollectedMethod,
  });

  bool get isCashOnDelivery =>
      paymentMethod.toLowerCase().contains('cash') && orderType == 'delivery';

  String get kitchenBagCode => 'KB-$id';
  String get customerDropCode => 'DROP-$id';

  bool get requiresCashCollection => !isPaid;

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get paymentMethodDisplay {
    if (paymentCollectedMethod == 'credit_card' ||
        paymentMethod.toLowerCase().contains('credit')) {
      return 'COD • Credit Card (POS)';
    }
    if (paymentCollectedMethod == 'debit_card' ||
        paymentMethod.toLowerCase().contains('debit')) {
      return 'COD • Debit Card (POS)';
    }
    if (paymentCollectedMethod == 'cash' ||
        paymentMethod.toLowerCase().contains('cash')) {
      return 'COD • Cash';
    }
    return paymentMethod;
  }

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
    String? assignedDriverId,
    String? assignedDriverName,
    String? paymentCollectedMethod,
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
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      paymentCollectedMethod:
          paymentCollectedMethod ?? this.paymentCollectedMethod,
    );
  }

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    DeliveryOrderStatus parseStatus(String? s) {
      switch (s?.toLowerCase()) {
        case 'out_for_delivery':
        case 'outfordelivery':
          return DeliveryOrderStatus.outForDelivery;
        case 'delivered':
          return DeliveryOrderStatus.delivered;
        case 'picked_up':
        case 'pickedup':
          return DeliveryOrderStatus.pickedUp;
        default:
          return DeliveryOrderStatus.assigned;
      }
    }

    String parseAddress(dynamic addr) {
      if (addr == null) return '';
      if (addr is String) return addr;
      if (addr is Map) {
        final street = addr['street']?.toString() ?? '';
        final apt = addr['apartment']?.toString() ?? '';
        final city = addr['city']?.toString() ?? '';
        final postal = addr['postalCode']?.toString() ?? '';
        return [street, if (apt.isNotEmpty) apt, city, postal].where((s) => s.isNotEmpty).join(', ');
      }
      return addr.toString();
    }

    return DeliveryOrder(
      id: json['id'] as String? ?? json['orderId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? 'Customer',
      customerPhone: json['customerPhone'] as String? ?? '',
      deliveryAddress: parseAddress(json['deliveryAddress']),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      orderTime: json['orderTime'] != null
          ? DateTime.tryParse(json['orderTime'].toString()) ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          0.0,
      paymentMethod: json['paymentMethod'] as String? ?? 'Cash on Delivery',
      isPaid: json['isPaid'] as bool? ?? (json['paymentStatus'] == 'paid'),
      status: parseStatus(json['status'] as String? ?? json['orderStatus'] as String?),
      barcodeCode: json['barcodeCode'] as String? ?? json['barcodeValue'] as String? ?? json['barcodeId'] as String? ?? '',
      qrCode: json['qrCode'] as String? ?? json['qrCodeValue'] as String? ?? '',
      deliveryNotes: json['deliveryNotes'] as String? ?? json['deliveryInstructions'] as String?,
      orderType: json['orderType'] as String? ?? json['fulfillmentType'] as String? ?? json['deliveryType'] as String? ?? 'delivery',
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'].toString())
          : null,
      assignedDriverId: json['assignedDriverId'] as String?,
      assignedDriverName: json['assignedDriverName'] as String?,
      paymentCollectedMethod: json['paymentCollectedMethod'] as String? ??
          json['collectedPaymentMethod'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'deliveryAddress': deliveryAddress,
    'items': items.map((i) => i.toJson()).toList(),
    'orderTime': orderTime.toIso8601String(),
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'tax': tax,
    'totalAmount': totalAmount,
    'paymentMethod': paymentMethod,
    'isPaid': isPaid,
    'status': status.name,
    'barcodeCode': barcodeCode,
    'qrCode': qrCode,
    if (deliveryNotes != null) 'deliveryNotes': deliveryNotes,
    'orderType': orderType,
    if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
    if (assignedDriverId != null) 'assignedDriverId': assignedDriverId,
    if (assignedDriverName != null) 'assignedDriverName': assignedDriverName,
    if (paymentCollectedMethod != null)
      'paymentCollectedMethod': paymentCollectedMethod,
  };
}
