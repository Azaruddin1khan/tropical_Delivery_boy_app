import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
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

  bool get _isTargetPickup {
    final t = widget.targetOrderCode?.toUpperCase() ?? '';
    return t.startsWith('KB') || t.contains('KB-') || t.contains('/KITCHEN');
  }

  bool get _isTargetDrop {
    final t = widget.targetOrderCode?.toUpperCase() ?? '';
    return t.startsWith('DROP') || t.contains('DROP-') || t.contains('/DROP');
  }

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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.limeGreenDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('OK, Got It'),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isProcessingScan = false);
      }
    });
  }

  bool _validateAndShowScanResult(
    BuildContext context,
    DeliveryOrder order,
    String rawCode,
  ) {
    final upper = rawCode.toUpperCase().trim();
    final isKitchenBagCode =
        upper.startsWith('KB') ||
        upper.contains('KB-') ||
        upper.contains('/KITCHEN');
    final isCustomerDropCode =
        upper.startsWith('DROP') ||
        upper.contains('DROP-') ||
        upper.contains('/DROP');

    // 1. If target was explicitly Kitchen Bag, but user scanned customer drop pass
    if (_isTargetPickup && isCustomerDropCode && !isKitchenBagCode) {
      _showCodeMismatchDialog(
        title: 'Customer Pass Scanned!',
        description:
            'You opened the scanner to pick up Order #${order.id} from the kitchen.\n\nPlease scan the Kitchen Bag barcode (KB-${order.id}) on the food parcel bag in the kitchen.',
        badgeText: 'WRONG CODE: NEED KITCHEN BAG',
        badgeColor: AppColors.errorRed,
      );
      return false;
    }

    // 2. If target was explicitly Customer Drop, but user scanned kitchen bag
    if (_isTargetDrop && isKitchenBagCode && !isCustomerDropCode) {
      _showCodeMismatchDialog(
        title: 'Kitchen Bag Scanned!',
        description:
            'This parcel was already picked up from the kitchen.\n\nTo confirm doorstep delivery, please scan the Customer Delivery Pass (DROP-${order.id}) from the customer\'s phone.',
        badgeText: 'WRONG CODE: NEED CUSTOMER PASS',
        badgeColor: AppColors.warningOrange,
      );
      return false;
    }

    // 3. If scanned kitchen bag, but parcel was already out for delivery
    if (isKitchenBagCode &&
        order.status == DeliveryOrderStatus.outForDelivery &&
        !_isTargetPickup) {
      _showCodeMismatchDialog(
        title: 'Parcel Already Picked Up!',
        description:
            'Order #${order.id} was already picked up from the kitchen and is out for delivery.\n\nTo confirm doorstep delivery, scan the Customer Delivery Pass (DROP-${order.id}) on the customer\'s phone.',
        badgeText: 'ALREADY ON THE WAY',
        badgeColor: AppColors.oceanBlue,
      );
      return false;
    }

    // Determine whether this action is Pickup or Drop:
    // If it's a customer drop pass, or target was drop, or order is already outForDelivery -> Drop
    final isDropAction =
        isCustomerDropCode ||
        _isTargetDrop ||
        order.status == DeliveryOrderStatus.outForDelivery;

    _showScanResultBottomSheet(
      context,
      order,
      forceDropHandover: isDropAction,
    );
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
          final isMine =
              ordDrvId == curId ||
              ordDrvName.contains(curName) ||
              curName.contains(ordDrvName);

          if (!isMine) {
            _showCodeMismatchDialog(
              title: 'Assigned to Another Courier!',
              description:
                  'This order is assigned to another delivery courier (${order.assignedDriverName ?? "another courier"}).\n\nYou can only scan and process orders assigned to you.',
              badgeText: 'NOT YOUR ORDER',
              badgeColor: AppColors.errorRed,
            );
            return;
          }
        }

        if (widget.targetOrderCode != null &&
            widget.targetOrderCode!.isNotEmpty) {
          final targetClean = widget.targetOrderCode!
              .toUpperCase()
              .replaceAll('KB-', '')
              .replaceAll('DROP-', '')
              .replaceAll('HTTPS://TROPICALGYROS.DEMO/ORDER/', '')
              .replaceAll('/DROP', '')
              .replaceAll('/KITCHEN', '')
              .trim();
          final orderClean = order.id.toUpperCase().trim();
          if (targetClean != orderClean) {
            _showCodeMismatchDialog(
              title: 'Wrong Order Scanned!',
              description:
                  'You opened the scanner for Order #${widget.targetOrderCode}.\n\nThe scanned code is for a different order (#${order.id}).',
              badgeText: 'WRONG ORDER',
              badgeColor: AppColors.errorRed,
            );
            return;
          }
        }

        _validateAndShowScanResult(context, order, rawCode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scanned code "$rawCode" — no matching active order found.',
            ),
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
            content: Text(
              'No active order matched the code "$code". Please verify your entry.',
            ),
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
        final isMine =
            ordDrvId == curId ||
            ordDrvName.contains(curName) ||
            curName.contains(ordDrvName);

        if (!isMine) {
          _showCodeMismatchDialog(
            title: 'Assigned to Another Courier!',
            description:
                'This order is assigned to another delivery courier (${order.assignedDriverName ?? "another courier"}).\n\nYou can only scan and process orders assigned to you.',
            badgeText: 'NOT YOUR ORDER',
            badgeColor: AppColors.errorRed,
          );
          return;
        }
      }

      if (widget.targetOrderCode != null &&
          widget.targetOrderCode!.isNotEmpty) {
        final targetClean = widget.targetOrderCode!
            .toUpperCase()
            .replaceAll('KB-', '')
            .replaceAll('DROP-', '')
            .replaceAll('HTTPS://TROPICALGYROS.DEMO/ORDER/', '')
            .replaceAll('/DROP', '')
            .replaceAll('/KITCHEN', '')
            .trim();
        final orderClean = order.id.toUpperCase().trim();
        if (targetClean != orderClean) {
          _showCodeMismatchDialog(
            title: 'Wrong Order Entered!',
            description:
                'You opened the scanner for Order #${widget.targetOrderCode}.\n\nThe entered code is for a different order (#${order.id}).',
            badgeText: 'WRONG ORDER',
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

  void _showScanResultBottomSheet(
    BuildContext context,
    DeliveryOrder order, {
    bool forceDropHandover = false,
  }) {
    _isProcessingScan = true;

    final isPickupAction =
        !forceDropHandover &&
        order.status == DeliveryOrderStatus.assigned &&
        order.orderType == 'delivery';

    final isDropAction =
        forceDropHandover || order.status == DeliveryOrderStatus.outForDelivery;

    // Track COD cash checkbox inside the modal
    bool isCashCollected = !order.requiresCashCollection;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Title & Badge: Green for Pickup, Sky Blue for Drop
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPickupAction
                              ? 'Kitchen Pickup Verification'
                              : (order.orderType == 'pickup'
                                    ? 'Counter Pickup Verification'
                                    : 'Customer Doorstep Handover'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Order #${order.id}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isPickupAction
                            ? AppColors.limeGreenLight
                            : AppColors.oceanBlueLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPickupAction ? 'KITCHEN PICKUP' : 'DOORSTEP DROP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isPickupAction
                              ? AppColors.limeGreenDark
                              : AppColors.oceanBlueDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Customer & Address Info Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: AppColors.textDark,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            order.customerName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            order.customerPhone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: AppColors.oceanBlue,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.deliveryAddress,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Text(
                        '${order.totalItemCount} items: ${order.items.map((i) => "${i.quantity}x ${i.name}").join(', ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Payment Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: order.requiresCashCollection
                        ? AppColors.warningOrangeLight
                        : AppColors.limeGreenLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: order.requiresCashCollection
                          ? AppColors.warningOrange.withValues(alpha: 0.3)
                          : AppColors.limeGreenDark.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            order.requiresCashCollection
                                ? Icons.payments_rounded
                                : Icons.check_circle_rounded,
                            size: 18,
                            color: order.requiresCashCollection
                                ? AppColors.warningOrange
                                : AppColors.limeGreenDark,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            order.requiresCashCollection
                                ? 'Cash to Collect (COD)'
                                : 'Payment Verified (Online)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: order.requiresCashCollection
                                  ? AppColors.warningOrange
                                  : AppColors.limeGreenDark,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${AppConstants.currency}${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),

                // COD Cash Collection Confirmation Checkbox
                if (isDropAction && order.requiresCashCollection) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      setSheetState(() {
                        isCashCollected = !isCashCollected;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isCashCollected,
                            activeColor: AppColors.limeGreenDark,
                            onChanged: (val) {
                              setSheetState(() {
                                isCashCollected = val ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              'I have collected ${AppConstants.currency}${order.totalAmount.toStringAsFixed(2)} cash from customer',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Action Buttons: Green for Pickup, Sky Blue for Drop
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
                        child: const Text('View Order'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPickupAction
                              ? AppColors.limeGreen // Green for Pickup
                              : (isDropAction && !isCashCollected
                                    ? Colors.grey
                                    : AppColors.oceanBlue), // Sky Blue for Drop
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: (isDropAction && !isCashCollected)
                            ? null
                            : () {
                                Navigator.of(bottomSheetContext).pop();
                                final state = StaffStateScope.read(context);

                                if (isPickupAction) {
                                  state.updateOrderStatus(
                                    order.id,
                                    DeliveryOrderStatus.outForDelivery,
                                  );
                                  final updatedOrder =
                                      state.findOrderByCode(order.id) ??
                                      order.copyWith(
                                        status:
                                            DeliveryOrderStatus.outForDelivery,
                                      );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Order #${order.id} picked up! Starting navigation 🛵',
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
                                        'Order #${order.id} handed over at pickup counter! 🥡',
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
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  }
                                }
                              },
                        child: Text(
                          isPickupAction
                              ? '🛵 Confirm Pickup'
                              : (order.orderType == 'pickup'
                                    ? 'Complete Pickup'
                                    : '✅ Confirm Delivered'),
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
    // Determine Theme Color: Green for Pickup, Sky Blue for Drop, Neutral Yellow for general
    final themeColor = _isTargetPickup
        ? AppColors.limeGreen
        : (_isTargetDrop ? AppColors.oceanBlue : AppColors.tropicalYellow);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar: Back, Title & Flash Toggle
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (Navigator.of(context).canPop())
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  else
                    const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Scan Order Barcode / QR',
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
                    },
                  ),
                ],
              ),
            ),

            // 2. Context Indicator Banner (Green for Pickup, Sky Blue for Drop)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              color: _isTargetPickup
                  ? AppColors.limeGreenLight
                  : (_isTargetDrop
                        ? AppColors.oceanBlueLight
                        : const Color(0xFF1E293B)),
              child: Row(
                children: [
                  Icon(
                    _isTargetPickup
                        ? Icons.inventory_2_rounded
                        : (_isTargetDrop
                              ? Icons.home_rounded
                              : Icons.qr_code_scanner_rounded),
                    size: 16,
                    color: _isTargetPickup
                        ? AppColors.limeGreenDark
                        : (_isTargetDrop ? AppColors.oceanBlueDark : Colors.white70),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.targetOrderCode != null
                          ? (_isTargetPickup
                                ? 'Target Kitchen Bag: ${widget.targetOrderCode} • Scan parcel bag barcode'
                                : 'Target Customer Pass: ${widget.targetOrderCode} • Scan customer phone QR')
                          : 'Point camera at Kitchen Bag Barcode (KB-) or Customer Pass (DROP-)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _isTargetPickup
                            ? AppColors.limeGreenDark
                            : (_isTargetDrop
                                  ? AppColors.oceanBlueDark
                                  : Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Live Camera Viewfinder
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Camera Stream
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
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white38,
                                size: 48,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Camera Ready\nAlign Barcode or QR code inside frame',
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

                  // Translucent dark mask
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),
                  ),

                  // Viewfinder Frame (Styled dynamically with Green or Sky Blue theme)
                  Container(
                    width: 270,
                    height: 270,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: themeColor, width: 2.5),
                    ),
                    child: Stack(
                      children: [
                        // Animated Scanning Laser Bar
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
                                  color: themeColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: themeColor.withValues(alpha: 0.85),
                                      blurRadius: 10,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Viewfinder Corner Brackets
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: themeColor, width: 4.5),
                                left: BorderSide(color: themeColor, width: 4.5),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: themeColor, width: 4.5),
                                right: BorderSide(
                                  color: themeColor,
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
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: themeColor,
                                  width: 4.5,
                                ),
                                left: BorderSide(color: themeColor, width: 4.5),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: themeColor,
                                  width: 4.5,
                                ),
                                right: BorderSide(
                                  color: themeColor,
                                  width: 4.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Prompt Pill
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.center_focus_strong,
                            color: themeColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isTargetPickup
                                ? 'Align Kitchen Bag Barcode (KB-)'
                                : (_isTargetDrop
                                      ? 'Align Customer Pass (DROP-)'
                                      : 'Point camera at Barcode / QR'),
                            style: const TextStyle(
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

            // 4. Bottom Card: Manual Code Entry ONLY (NO bypass tap buttons!)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manual Code Entry',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualInputController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: _isTargetPickup
                                ? 'Enter KB- code (e.g. KB-TRP-...)'
                                : (_isTargetDrop
                                      ? 'Enter DROP- code (e.g. DROP-TRP-...)'
                                      : 'Enter Code (KB-... or DROP-...)'),
                            isDense: true,
                            prefixIcon: const Icon(
                              Icons.keyboard_alt_rounded,
                              size: 18,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTargetPickup
                              ? AppColors.limeGreen
                              : (_isTargetDrop
                                    ? AppColors.oceanBlue
                                    : AppColors.textDark),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
