enum StaffRole {
  deliveryStaff(
    'Delivery Staff',
    'Staff delivering orders and handling pickups',
  );

  // Aliases for seamless compatibility
  static const StaffRole deliveryDriver = StaffRole.deliveryStaff;
  static const StaffRole cashier = StaffRole.deliveryStaff;

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

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Staff Courier',
      email: json['email'] as String? ?? '',
      role: StaffRole.deliveryStaff,
      phone: json['phone'] as String? ?? '+1 (242) 555-0100',
      isOnline: json['isOnline'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.title,
    'phone': phone,
    'isOnline': isOnline,
  };
}
