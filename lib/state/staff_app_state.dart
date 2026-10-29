import 'package:flutter/material.dart';

import '../models/staff_user.dart';
import '../models/order_item.dart';
import '../models/delivery_order.dart';

class StaffAppState extends ChangeNotifier {
  StaffUser? _currentUser;
  List<DeliveryOrder> _assignedOrders = [];
  List<DeliveryOrder> _deliveryHistory = [];

  StaffUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  List<DeliveryOrder> get assignedOrders => List.unmodifiable(_assignedOrders);
  List<DeliveryOrder> get deliveryHistory =>
      List.unmodifiable(_deliveryHistory);

  int get pendingCashOrdersCount => _assignedOrders
      .where((o) => o.requiresCashCollection && o.orderType == 'delivery')
      .length;

  double get totalCollectedCashToday => _deliveryHistory
      .where((o) => o.isCashOnDelivery && o.isPaid)
      .fold(0.0, (sum, o) => sum + o.totalAmount);

  StaffAppState() {
    // Populate realistic initial mock data
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    _assignedOrders = [
      DeliveryOrder(
        id: 'TG-8092',
        customerName: 'Marcus Bennett',
        customerPhone: '+1 (305) 555-0143',
        deliveryAddress: '1420 Ocean Drive, Apt 3B, Miami Beach, FL 33139',
        orderTime: now.subtract(const Duration(minutes: 25)),
        items: const [
          OrderItem(
            name: 'Jerk Chicken Gyro',
            quantity: 2,
            unitPrice: 12.35,
            options: 'Extra Garlic White Sauce, Extra Onions',
          ),
          OrderItem(
            name: 'Large Salad - Conch',
            quantity: 1,
            unitPrice: 17.60,
            options: 'Mango Feta Dressing',
          ),
          OrderItem(name: 'Crispy Fries', quantity: 2, unitPrice: 2.79),
          OrderItem(name: 'Tropical Soda', quantity: 2, unitPrice: 2.79),
        ],
        subtotal: 50.67,
        deliveryFee: 3.99,
        tax: 3.55,
        totalAmount: 58.21,
        paymentMethod: 'Cash on Delivery (COD)',
        isPaid: false, // Must collect cash!
        status: DeliveryOrderStatus.outForDelivery,
        barcodeCode: 'TG-BC-8092',
        qrCode: 'TG-QR-8092',
        deliveryNotes: 'Call upon arrival. Front gate code is #1024.',
        orderType: 'delivery',
      ),
      DeliveryOrder(
        id: 'TG-8095',
        customerName: 'Aaliyah Davis',
        customerPhone: '+1 (305) 555-0188',
        deliveryAddress: '1120 Collins Ave, Suite 6, Miami Beach, FL 33139',
        orderTime: now.subtract(const Duration(minutes: 15)),
        items: const [
          OrderItem(
            name: 'BBQ Salmon Gyro',
            quantity: 1,
            unitPrice: 15.40,
            options: 'Regular Crema',
          ),
          OrderItem(
            name: 'Jerk Pork Bowl',
            quantity: 1,
            unitPrice: 14.55,
            options: 'Sweet Caramelized Plantains',
          ),
          OrderItem(name: 'Bottled Water', quantity: 1, unitPrice: 1.67),
        ],
        subtotal: 31.62,
        deliveryFee: 3.99,
        tax: 2.21,
        totalAmount: 37.82,
        paymentMethod: 'Credit Card (•••• 4242)',
        isPaid: true, // Already paid online!
        status: DeliveryOrderStatus.assigned,
        barcodeCode: 'TG-BC-8095',
        qrCode: 'TG-QR-8095',
        deliveryNotes: 'Leave on porch table if unattended.',
        orderType: 'delivery',
      ),
      DeliveryOrder(
        id: 'TG-8098',
        customerName: 'Derrick Vance',
        customerPhone: '+1 (305) 555-0177',
        deliveryAddress: 'Pickup Counter • 740 Ocean Dr (Tropical Gyros)',
        orderTime: now.subtract(const Duration(minutes: 10)),
        items: const [
          OrderItem(
            name: 'Meat Gyros - 3 Cheese Burgers',
            quantity: 1,
            unitPrice: 11.11,
          ),
          OrderItem(name: 'Shrimp Gyro Bowl', quantity: 1, unitPrice: 15.95),
        ],
        subtotal: 27.06,
        deliveryFee: 0.00,
        tax: 1.89,
        totalAmount: 28.95,
        paymentMethod: 'Counter Cash (Unpaid)',
        isPaid: false, // Cashier collects at pickup!
        status: DeliveryOrderStatus.assigned,
        barcodeCode: 'TG-BC-8098',
        qrCode: 'TG-QR-8098',
        deliveryNotes: 'Customer arriving on foot for takeout.',
        orderType: 'pickup',
      ),
    ];

    _deliveryHistory = [
      DeliveryOrder(
        id: 'TG-8080',
        customerName: 'Carlos Mendoza',
        customerPhone: '+1 (305) 555-0112',
        deliveryAddress: '900 Ocean Drive, Apt 2A, Miami Beach, FL',
        orderTime: now.subtract(const Duration(hours: 2, minutes: 15)),
        deliveredAt: now.subtract(const Duration(hours: 1, minutes: 40)),
        items: const [
          OrderItem(name: 'Jerk Chicken Bowl', quantity: 2, unitPrice: 15.55),
          OrderItem(name: 'Tropical Soda', quantity: 2, unitPrice: 2.79),
        ],
        subtotal: 36.68,
        deliveryFee: 3.99,
        tax: 2.57,
        totalAmount: 43.24,
        paymentMethod: 'Cash on Delivery (COD)',
        isPaid: true,
        status: DeliveryOrderStatus.delivered,
        barcodeCode: 'TG-BC-8080',
        qrCode: 'TG-QR-8080',
        orderType: 'delivery',
      ),
      DeliveryOrder(
        id: 'TG-8076',
        customerName: 'Elena Rostova',
        customerPhone: '+1 (305) 555-0131',
        deliveryAddress: '1500 Washington Ave, Miami Beach, FL',
        orderTime: now.subtract(const Duration(hours: 3)),
        deliveredAt: now.subtract(const Duration(hours: 2, minutes: 10)),
        items: const [
          OrderItem(
            name: 'Large Salad - Grilled Veggies',
            quantity: 1,
            unitPrice: 13.75,
          ),
          OrderItem(name: 'Side Salad (w) Gyro', quantity: 1, unitPrice: 3.85),
        ],
        subtotal: 17.60,
        deliveryFee: 3.99,
        tax: 1.23,
        totalAmount: 22.82,
        paymentMethod: 'Apple Pay',
        isPaid: true,
        status: DeliveryOrderStatus.delivered,
        barcodeCode: 'TG-BC-8076',
        qrCode: 'TG-QR-8076',
        orderType: 'delivery',
      ),
      DeliveryOrder(
        id: 'TG-8069',
        customerName: 'Jordan Smith',
        customerPhone: '+1 (305) 555-0164',
        deliveryAddress: 'Pickup Counter • 740 Ocean Dr',
        orderTime: now.subtract(const Duration(hours: 4)),
        deliveredAt: now.subtract(const Duration(hours: 3, minutes: 30)),
        items: const [
          OrderItem(
            name: 'Sea Food Gyros - Lobster',
            quantity: 1,
            unitPrice: 18.70,
          ),
          OrderItem(name: 'Crispy Fries', quantity: 1, unitPrice: 2.79),
        ],
        subtotal: 21.49,
        deliveryFee: 0.00,
        tax: 1.50,
        totalAmount: 22.99,
        paymentMethod: 'Credit Card',
        isPaid: true,
        status: DeliveryOrderStatus.pickedUp,
        barcodeCode: 'TG-BC-8069',
        qrCode: 'TG-QR-8069',
        orderType: 'pickup',
      ),
    ];
  }

  bool login({
    required String username,
    required String password,
    required StaffRole role,
  }) {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      return false;
    }

    _currentUser = StaffUser(
      id: 'staff_${DateTime.now().millisecondsSinceEpoch}',
      name: role == StaffRole.deliveryDriver
          ? 'Driver Devon Miller'
          : 'Cashier Maya Lin',
      email: username.trim(),
      role: role,
      phone: '+1 (305) 555-0100',
      isOnline: true,
    );

    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void updateOrderStatus(String orderId, DeliveryOrderStatus newStatus) {
    final index = _assignedOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final updated = _assignedOrders[index].copyWith(status: newStatus);
      _assignedOrders[index] = updated;
      notifyListeners();
    }
  }

  void markCashReceived(String orderId) {
    final index = _assignedOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final updated = _assignedOrders[index].copyWith(isPaid: true);
      _assignedOrders[index] = updated;
      notifyListeners();
    }
  }

  void markOrderDelivered(String orderId) {
    final index = _assignedOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _assignedOrders[index];
      final completed = order.copyWith(
        status: DeliveryOrderStatus.delivered,
        isPaid: true, // If cash wasn't marked before, finishing delivery confirms collection
        deliveredAt: DateTime.now(),
      );
      _assignedOrders.removeAt(index);
      _deliveryHistory.insert(0, completed);
      notifyListeners();
    }
  }

  void markOrderPickedUp(String orderId) {
    final index = _assignedOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _assignedOrders[index];
      final completed = order.copyWith(
        status: DeliveryOrderStatus.pickedUp,
        isPaid: true,
        deliveredAt: DateTime.now(),
      );
      _assignedOrders.removeAt(index);
      _deliveryHistory.insert(0, completed);
      notifyListeners();
    }
  }

  DeliveryOrder? findOrderByCode(String code) {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) return null;

    // First search active assigned orders
    for (final o in _assignedOrders) {
      if (o.id.toUpperCase() == clean ||
          o.barcodeCode.toUpperCase() == clean ||
          o.qrCode.toUpperCase() == clean ||
          clean.contains(o.id.toUpperCase())) {
        return o;
      }
    }

    // Then search history
    for (final o in _deliveryHistory) {
      if (o.id.toUpperCase() == clean ||
          o.barcodeCode.toUpperCase() == clean ||
          o.qrCode.toUpperCase() == clean ||
          clean.contains(o.id.toUpperCase())) {
        return o;
      }
    }

    return null;
  }

  void resetMockData() {
    _initMockData();
    notifyListeners();
  }
}
