import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/staff_user.dart';
import '../state/staff_state_scope.dart';
import 'assigned_orders_screen.dart';
import 'barcode_scanner_screen.dart';
import 'delivery_history_screen.dart';
import 'login_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AssignedOrdersScreen(),
    BarcodeScannerScreen(),
    DeliveryHistoryScreen(),
  ];

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out Staff'),
        content: const Text(
          'Are you sure you want to end your staff shift session?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              final state = StaffStateScope.read(context);
              state.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showStaffProfile(BuildContext context) {
    final state = StaffStateScope.read(context);
    final user = state.currentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.tropicalYellowLight,
                    child: Text(
                      user?.name.substring(0, 1) ?? 'S',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.tropicalYellowDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Staff Member',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.role.title ?? 'Courier',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.oceanBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.textDark,
                ),
                title: const Text('Reset Mock Data to Initial State'),
                subtitle: const Text('Restores 3 active orders & history'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  state.resetMockData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Mock order data has been reset to defaults!',
                      ),
                      backgroundColor: AppColors.limeGreenDark,
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.errorRed,
                ),
                title: const Text(
                  'End Shift / Sign Out',
                  style: TextStyle(
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmLogout(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = StaffStateScope.of(context);
    final user = state.currentUser;
    final activeCount = state.assignedOrders.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.tropicalYellowLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('🌴', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tropical Gyros',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  user?.role == StaffRole.cashier
                      ? 'Counter Cashier Terminal'
                      : 'Delivery Courier Terminal',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Staff Account',
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceVariant,
              child: Text(
                user?.name.substring(0, 1) ?? 'S',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            onPressed: () => _showStaffProfile(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: Colors.white,
        elevation: 4,
        indicatorColor: AppColors.tropicalYellowLight,
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: activeCount > 0,
              label: Text(
                '$activeCount',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Icon(Icons.moped_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: activeCount > 0,
              label: Text(
                '$activeCount',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Icon(
                Icons.moped_rounded,
                color: AppColors.tropicalYellowDark,
              ),
            ),
            label: 'Assigned',
          ),
          const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.oceanBlue,
            ),
            label: 'Scan Pickup',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(
              Icons.history_rounded,
              color: AppColors.limeGreenDark,
            ),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
