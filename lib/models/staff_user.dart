enum StaffRole {
  deliveryDriver(
    'Delivery Courier',
    'Couriers delivering orders to customer homes',
  ),
  cashier('Counter Cashier', 'Staff at store counter validating pickup orders');

  final String title;
  final String description;
  const StaffRole(this.title, this.description);
}

class StaffUser {
  final String id;
  final String name;
  final String email;
  final StaffRole role;
  final String phone;
  final bool isOnline;

  const StaffUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    this.isOnline = true,
  });

  StaffUser copyWith({
    String? id,
    String? name,
    String? email,
    StaffRole? role,
    String? phone,
    bool? isOnline,
  }) {
    return StaffUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
