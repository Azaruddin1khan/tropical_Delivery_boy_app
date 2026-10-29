import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/demo_banner.dart';
import '../core/widgets/primary_button.dart';
import '../models/delivery_order.dart';
import '../state/staff_state_scope.dart';
import 'order_details_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final _manualInputController = TextEditingController();
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _onSimulateScan(
    BuildContext context, {
    String sampleCode = 'TG-BC-8098',
  }) {
    final state = StaffStateScope.read(context);
    final order =
        state.findOrderByCode(sampleCode) ?? state.assignedOrders.firstOrNull;

    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No matching active order found to scan.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    _showScanResultBottomSheet(context, order);
  }

  void _handleManualLookup(BuildContext context) {
    final code = _manualInputController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an Order ID or Barcode number'),
        ),
      );
      return;
    }

    final state = StaffStateScope.read(context);
    final order = state.findOrderByCode(code);

    if (order == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Order Not Found'),
          content: Text('No active order matched the code "$code".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    _manualInputController.clear();
    _showScanResultBottomSheet(context, order);
  }

  void _showScanResultBottomSheet(BuildContext context, DeliveryOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.limeGreenLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: AppColors.limeGreenDark,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Scan Verified (Demo)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.limeGreenDark,
                            ),
                          ),
                          Text(
                            'Code: ${order.barcodeCode}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.id,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Customer & Item info
              Text(
                'Customer: ${order.customerName}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${order.totalItemCount} items • ${order.items.map((i) => i.name).join(', ')}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // Payment Status summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: order.requiresCashCollection
                      ? AppColors.warningOrangeLight
                      : AppColors.limeGreenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.requiresCashCollection
                          ? 'Cash Due: \$${order.totalAmount.toStringAsFixed(2)}'
                          : 'Payment Already Verified (${order.paymentMethod})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: order.requiresCashCollection
                            ? AppColors.warningOrange
                            : AppColors.limeGreenDark,
                      ),
                    ),
                    Text(
                      '${AppConstants.currency}${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                OrderDetailsScreen(orderId: order.id),
                          ),
                        );
                      },
                      child: const Text('View Full Order'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.limeGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                        final state = StaffStateScope.read(context);
                        if (order.orderType == 'pickup') {
                          state.markOrderPickedUp(order.id);
                        } else {
                          state.markOrderDelivered(order.id);
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Order ${order.id} verified and completed! (Local demo state)',
                            ),
                            backgroundColor: AppColors.limeGreenDark,
                          ),
                        );
                      },
                      child: Text(
                        order.orderType == 'pickup'
                            ? 'Complete Pickup'
                            : 'Confirm Delivered',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top instructions bar
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  const DemoBanner(
                    label: 'PICKUP BARCODE SCANNER • UI-Only Prototype',
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Scan Customer Order Barcode / QR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isFlashOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          color: _isFlashOn
                              ? AppColors.tropicalYellow
                              : Colors.white70,
                        ),
                        onPressed: () {
                          setState(() => _isFlashOn = !_isFlashOn);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isFlashOn
                                    ? 'Simulated Torch ON 💡'
                                    : 'Simulated Torch OFF',
                              ),
                              duration: const Duration(milliseconds: 700),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Camera Viewfinder Simulation
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dim background
                  Container(color: Colors.black87),

                  // Viewfinder Frame
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.tropicalYellow,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Animated Scanning Line
                        AnimatedBuilder(
                          animation: _animController,
                          builder: (context, child) {
                            return Positioned(
                              top: _animController.value * 230 + 10,
                              left: 10,
                              right: 10,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.limeGreen,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.limeGreen.withValues(
                                        alpha: 0.8,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Corner brackets
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.tropicalYellow,
                                  width: 4,
                                ),
                                left: BorderSide(
                                  color: AppColors.tropicalYellow,
                                  width: 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.tropicalYellow,
                                  width: 4,
                                ),
                                right: BorderSide(
                                  color: AppColors.tropicalYellow,
                                  width: 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.tropicalYellow,
                                  width: 4,
                                ),
                                left: BorderSide(
                                  color: AppColors.tropicalYellow,
                                  width: 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.tropicalYellow,
                                  width: 4,
                                ),
                                right: BorderSide(
                                  color: AppColors.tropicalYellow,
                                  width: 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Prompt Text
                  Positioned(
                    bottom: 30,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Align customer QR code or Barcode inside the frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Controls & Manual Entry
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    text: 'Simulate Scan Customer Barcode (Demo)',
                    icon: Icons.qr_code_2_rounded,
                    variant: ButtonVariant.primary,
                    width: double.infinity,
                    onPressed: () => _onSimulateScan(context),
                  ),
                  const SizedBox(height: 12),

                  // Manual ID Entry
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualInputController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: 'Or enter Order ID (e.g. TG-8098)',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _handleManualLookup(context),
                        child: const Text('Verify'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
