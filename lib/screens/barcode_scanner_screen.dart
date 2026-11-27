import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/demo_banner.dart';
import '../models/delivery_order.dart';
import '../state/staff_app_state.dart';
import '../state/staff_state_scope.dart';
import 'delivery_route_map_screen.dart';
import 'order_details_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final String? targetOrderCode;

  const BarcodeScannerScreen({
    super.key,
    this.targetOrderCode,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late final MobileScannerController _scannerController;
  final _manualInputController = TextEditingController();
  bool _isFlashOn = false;
  bool _isProcessingScan = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scannerController = MobileScannerController(
      autoStart: true,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _showCodeMismatchDialog({
    required String title,
    required String description,
    required String badgeText,
    required Color badgeColor,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: badgeColor, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textDark),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.limeGreenDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                setState(() => _isProcessingScan = false);
              }
            },
            child: const Text('OK, Got It'),
          ),
        ],
      ),
    );
  }

  bool _validateAndShowScanResult(BuildContext context, DeliveryOrder order, String rawCode) {
    final upper = rawCode.toUpperCase().trim();
    final isCustomerDropCode = upper.startsWith('DROP') ||
        upper.contains('DROP') ||
        upper.contains('/DROP');
    final isKitchenBagCode = upper.startsWith('KB') ||
        upper.contains('KB-') ||
        upper.contains('/KITCHEN');

    // 1. Kitchen Pickup Validation:
    // When the order is in 'assigned' status (waiting for kitchen pickup):
    // Scanning the Customer Drop Pass MUST NOT trigger pickup!
    if (order.status == DeliveryOrderStatus.assigned && order.orderType == 'delivery') {
      if (isCustomerDropCode) {
        _showCodeMismatchDialog(
          title: 'Customer Drop Pass Scanned!',
          description:
              'Yeh Customer ka Doorstep Delivery (Drop) barcode hai.\n\nKitchen se pickup karne ke liye parcel/bag par laga Kitchen Bag Barcode (KB-${order.id}) scan karein!',
          badgeText: 'WRONG CODE: CANNOT PICKUP',
          badgeColor: AppColors.errorRed,
        );
        return false;
      }
    }

    // 2. Doorstep Handover Validation:
    // When the order is already 'outForDelivery' (on the way / at doorstep):
    // Scanning the Kitchen Bag code MUST NOT complete delivery!
    if (order.status == DeliveryOrderStatus.outForDelivery) {
      if (isKitchenBagCode) {
        _showCodeMismatchDialog(
          title: 'Kitchen Bag Code Scanned!',
          description:
              'Kitchen bag pehle hi pickup ho chuka hai!\n\nCustomer ko delivery handover karne ke liye customer ke phone se "Customer Delivery Pass" (DROP-${order.id}) scan karein.',
          badgeText: 'ALREADY PICKED UP',
          badgeColor: AppColors.warningOrange,
        );
        return false;
      }
    }

    _showScanResultBottomSheet(context, order);
    return true;
  }

  void _handleLiveScanDetected(String rawCode) async {
    if (_isProcessingScan) return;
    _isProcessingScan = true;

    final state = StaffStateScope.read(context);
    try {
      final order = await state.findOrderByCodeOrFetch(rawCode);

      if (!mounted) return;

      if (order != null) {
        final user = state.currentUser;
        if (user != null &&
            order.assignedDriverId != null &&
            order.assignedDriverId!.isNotEmpty) {
          final curId = user.id.toLowerCase();
          final curName = user.name.toLowerCase();
          final ordDrvId = (order.assignedDriverId ?? '').toLowerCase();
          final ordDrvName = (order.assignedDriverName ?? '').toLowerCase();
          final isMine = ordDrvId == curId ||
              ordDrvName.contains(curName) ||
              curName.contains(ordDrvName);

          if (!isMine) {
            _showCodeMismatchDialog(
              title: 'Assigned to Another Courier!',
              description:
                  'Yeh order kisi aur delivery courier (${order.assignedDriverName}) ko assigned hai!\n\nAap sirf apne assigned orders hi pickup kar sakte hain.',
              badgeText: 'NOT YOUR ORDER',
              badgeColor: AppColors.errorRed,
            );
            return;
          }
        }

        _validateAndShowScanResult(context, order, rawCode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanned code "$rawCode" — no matching active order found.'),
            backgroundColor: AppColors.warningOrange,
            duration: const Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _isProcessingScan = false);
          }
        });
      }
    } on OrderAssignmentException catch (e) {
      if (!mounted) return;
      _showCodeMismatchDialog(
        title: 'Assigned to Another Courier!',
        description: e.message,
        badgeText: 'NOT YOUR ORDER',
        badgeColor: AppColors.errorRed,
      );
    }
  }

  void _onSimulateScan(
    BuildContext context, {
    String? sampleCode,
  }) {
    if (_isProcessingScan) return;
    final state = StaffStateScope.read(context);
    DeliveryOrder? order;
    if (sampleCode != null && sampleCode.isNotEmpty) {
      order = state.findOrderByCode(sampleCode);
    }

    if (order == null) {
      // First prioritize assigned delivery orders (kitchen bag pickup)
      final assignedDelivery = state.assignedOrders
          .where(
            (o) =>
                o.status == DeliveryOrderStatus.assigned &&
                o.orderType == 'delivery',
          )
          .firstOrNull;

      // Second prioritize out for delivery orders (doorstep handover)
      final enRouteDelivery = state.assignedOrders
          .where((o) => o.status == DeliveryOrderStatus.outForDelivery)
          .firstOrNull;

      // Third prioritize takeout orders
      final takeout = state.assignedOrders
          .where((o) => o.orderType == 'pickup')
          .firstOrNull;

      order = assignedDelivery ??
          enRouteDelivery ??
          takeout ??
          state.assignedOrders.firstOrNull;
    }

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

  void _handleManualLookup(BuildContext _) async {
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
    try {
      final order = await state.findOrderByCodeOrFetch(code);

      if (!mounted) return;

      if (order == null) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Order Not Found'),
            content: Text('No active order matched the code "$code".'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        return;
      }

      final user = state.currentUser;
      if (user != null &&
          order.assignedDriverId != null &&
          order.assignedDriverId!.isNotEmpty) {
        final curId = user.id.toLowerCase();
        final curName = user.name.toLowerCase();
        final ordDrvId = (order.assignedDriverId ?? '').toLowerCase();
        final ordDrvName = (order.assignedDriverName ?? '').toLowerCase();
        final isMine = ordDrvId == curId ||
            ordDrvName.contains(curName) ||
            curName.contains(ordDrvName);

        if (!isMine) {
          _showCodeMismatchDialog(
            title: 'Assigned to Another Courier!',
            description:
                'Yeh order kisi aur delivery courier (${order.assignedDriverName}) ko assigned hai!\n\nAap sirf apne assigned orders hi pickup kar sakte hain.',
            badgeText: 'NOT YOUR ORDER',
            badgeColor: AppColors.errorRed,
          );
          return;
        }
      }

      _manualInputController.clear();
      _validateAndShowScanResult(context, order, code);
    } on OrderAssignmentException catch (e) {
      if (!mounted) return;
      _showCodeMismatchDialog(
        title: 'Assigned to Another Courier!',
        description: e.message,
        badgeText: 'NOT YOUR ORDER',
        badgeColor: AppColors.errorRed,
      );
    }
  }

  void _showScanResultBottomSheet(BuildContext context, DeliveryOrder order) {
    _isProcessingScan = true;
    final isKitchenPickup = order.status == DeliveryOrderStatus.assigned &&
        order.orderType == 'delivery';
    final isDoorstepHandover =
        order.status == DeliveryOrderStatus.outForDelivery;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: SingleChildScrollView(
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
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isKitchenPickup
                                ? AppColors.limeGreenLight
                                : isDoorstepHandover
                                    ? AppColors.oceanBlueLight
                                    : AppColors.tropicalYellowLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isKitchenPickup
                                ? Icons.lunch_dining_rounded
                                : isDoorstepHandover
                                    ? Icons.verified_user_rounded
                                    : Icons.storefront_rounded,
                            color: isKitchenPickup
                                ? AppColors.limeGreenDark
                                : isDoorstepHandover
                                    ? AppColors.oceanBlueDark
                                    : AppColors.tropicalYellowDark,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isKitchenPickup
                                    ? 'Kitchen Bag Verified! ✓'
                                    : isDoorstepHandover
                                        ? 'Doorstep Handover Verified! ✓'
                                        : 'Takeout Bag Verified! ✓',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isKitchenPickup
                                      ? AppColors.limeGreenDark
                                      : isDoorstepHandover
                                          ? AppColors.oceanBlueDark
                                          : AppColors.tropicalYellowDark,
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
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.id,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Stage Notice Banner
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isKitchenPickup
                      ? AppColors.limeGreenLight
                      : isDoorstepHandover
                          ? AppColors.oceanBlueLight
                          : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isKitchenPickup
                          ? Icons.inventory_2_outlined
                          : isDoorstepHandover
                              ? Icons.home_rounded
                              : Icons.storefront_outlined,
                      size: 16,
                      color: isKitchenPickup
                          ? AppColors.limeGreenDark
                          : isDoorstepHandover
                              ? AppColors.oceanBlueDark
                              : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isKitchenPickup
                            ? 'Ready at Tropical Gyros Flagship Kitchen. Confirm pickup to begin route.'
                            : isDoorstepHandover
                                ? 'At Customer Doorstep. Confirm delivery handover.'
                                : 'Takeout counter ready for customer pickup.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isKitchenPickup
                              ? AppColors.limeGreenDark
                              : isDoorstepHandover
                                  ? AppColors.oceanBlueDark
                                  : AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Customer & Item info
              Text(
                'Customer: ${order.customerName}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                order.deliveryAddress,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${order.totalItemCount} items: ${order.items.map((i) => "${i.quantity}x ${i.name}").join(', ')}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              if (order.deliveryNotes != null &&
                  order.deliveryNotes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Note: "${order.deliveryNotes}"',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
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
                    Expanded(
                      child: Text(
                        order.requiresCashCollection
                            ? 'Cash Due: ${AppConstants.currency}${order.totalAmount.toStringAsFixed(2)} (COD)'
                            : 'Payment Verified (${order.paymentMethod})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: order.requiresCashCollection
                              ? AppColors.warningOrange
                              : AppColors.limeGreenDark,
                        ),
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
                        backgroundColor: isKitchenPickup
                            ? AppColors.limeGreen
                            : isDoorstepHandover
                                ? AppColors.oceanBlue
                                : AppColors.tropicalYellowDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                        final state = StaffStateScope.read(context);

                        if (isKitchenPickup) {
                          state.updateOrderStatus(
                            order.id,
                            DeliveryOrderStatus.outForDelivery,
                          );
                          final updatedOrder = state.findOrderByCode(order.id) ??
                              order.copyWith(
                                status: DeliveryOrderStatus.outForDelivery,
                              );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Order #${order.id} picked up from Flagship Kitchen! Starting navigation 🛵',
                              ),
                              backgroundColor: AppColors.limeGreenDark,
                            ),
                          );

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DeliveryRouteMapScreen(
                                order: updatedOrder,
                              ),
                            ),
                          );
                        } else if (order.orderType == 'pickup') {
                          state.markOrderPickedUp(order.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Order #${order.id} verified and picked up! 🥡',
                              ),
                              backgroundColor: AppColors.oceanBlueDark,
                            ),
                          );
                        } else {
                          state.markOrderDelivered(order.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Order #${order.id} delivered to ${order.customerName}! 🎉',
                              ),
                              backgroundColor: AppColors.limeGreenDark,
                            ),
                          );
                        }
                      },
                      child: Text(
                        isKitchenPickup
                            ? '🛵 Confirm Pickup'
                            : (order.orderType == 'pickup'
                                ? 'Complete Pickup'
                                : 'Confirm Delivered'),
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
    ).then((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _isProcessingScan = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = StaffStateScope.of(context);
    final activeOrders = state.assignedOrders;

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
                    label: 'PICKUP BARCODE SCANNER • Live Camera & QR Engine',
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
                        onPressed: () async {
                          setState(() => _isFlashOn = !_isFlashOn);
                          try {
                            await _scannerController.toggleTorch();
                          } catch (_) {}
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isFlashOn
                                      ? 'Camera Torch ON 💡'
                                      : 'Camera Torch OFF',
                                ),
                                duration: const Duration(milliseconds: 700),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Live Camera Viewfinder + Scanning Laser Bar Overlay
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Live Camera Preview from MobileScanner
                  Positioned.fill(
                    child: MobileScanner(
                      controller: _scannerController,
                      fit: BoxFit.cover,
                      onDetect: (capture) {
                        for (final barcode in capture.barcodes) {
                          final val = barcode.rawValue;
                          if (val != null && val.trim().isNotEmpty) {
                            _handleLiveScanDetected(val.trim());
                            break;
                          }
                        }
                      },
                      errorBuilder: (context, error) {
                        return Container(
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white38,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Camera Ready (Point at Barcode or Tap to Scan)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // 2. Translucent dark overlay outside the viewfinder frame
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),
                  ),

                  // 3. Viewfinder Frame with interactive Tap-to-Scan & animated laser bar
                  GestureDetector(
                    onTap: () => _onSimulateScan(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 270,
                      height: 270,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.tropicalYellow,
                          width: 2.5,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Animated Scanning Laser Line
                          AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              return Positioned(
                                top: _animController.value * 240 + 10,
                                left: 10,
                                right: 10,
                                child: Container(
                                  height: 3.5,
                                  decoration: BoxDecoration(
                                    color: AppColors.limeGreen,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.limeGreen.withValues(
                                          alpha: 0.85,
                                        ),
                                        blurRadius: 10,
                                        spreadRadius: 3,
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
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: AppColors.tropicalYellow,
                                    width: 4.5,
                                  ),
                                  left: BorderSide(
                                    color: AppColors.tropicalYellow,
                                    width: 4.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: AppColors.tropicalYellow,
                                    width: 4.5,
                                  ),
                                  right: BorderSide(
                                    color: AppColors.tropicalYellow,
                                    width: 4.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.tropicalYellow,
                                    width: 4.5,
                                  ),
                                  left: BorderSide(
                                    color: AppColors.tropicalYellow,
                                    width: 4.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.tropicalYellow,
                                    width: 4.5,
                                  ),
                                  right: BorderSide(
                                    color: AppColors.tropicalYellow,
                                    width: 4.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Prompt Text
                  Positioned(
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.center_focus_strong,
                            color: AppColors.limeGreen,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Point camera at Barcode / QR (or tap frame)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Controls & Manual Entry
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeOrders.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quick Scan Selectors (Demo):',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${activeOrders.length} active',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final ord in activeOrders)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                avatar: Icon(
                                  ord.status == DeliveryOrderStatus.assigned &&
                                          ord.orderType == 'delivery'
                                      ? Icons.lunch_dining_rounded
                                      : ord.status ==
                                              DeliveryOrderStatus.outForDelivery
                                          ? Icons.home_rounded
                                          : Icons.storefront_rounded,
                                  size: 15,
                                  color: ord.status ==
                                              DeliveryOrderStatus.assigned &&
                                          ord.orderType == 'delivery'
                                      ? AppColors.limeGreenDark
                                      : ord.status ==
                                              DeliveryOrderStatus.outForDelivery
                                          ? AppColors.oceanBlueDark
                                          : AppColors.tropicalYellowDark,
                                ),
                                label: Text(
                                  ord.status == DeliveryOrderStatus.assigned &&
                                          ord.orderType == 'delivery'
                                      ? 'Bag #${ord.id}'
                                      : ord.status ==
                                              DeliveryOrderStatus.outForDelivery
                                          ? 'Doorstep #${ord.id}'
                                          : 'Takeout #${ord.id}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                backgroundColor: ord.status ==
                                            DeliveryOrderStatus.assigned &&
                                        ord.orderType == 'delivery'
                                    ? AppColors.limeGreenLight
                                    : ord.status ==
                                            DeliveryOrderStatus.outForDelivery
                                        ? AppColors.oceanBlueLight
                                        : AppColors.tropicalYellowLight,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                onPressed: () => _onSimulateScan(
                                  context,
                                  sampleCode: ord.barcodeCode,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],


                  // Manual ID Entry
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualInputController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: 'Or enter Order ID (e.g. TG-8095)',
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
