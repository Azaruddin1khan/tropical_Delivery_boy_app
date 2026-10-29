import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/demo_banner.dart';
import '../core/widgets/primary_button.dart';
import '../core/widgets/status_chip.dart';
import '../models/delivery_order.dart';
import '../state/staff_state_scope.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isProcessing = false;

  void _handleMarkOutForDelivery(DeliveryOrder order) {
    final state = StaffStateScope.read(context);
    state.updateOrderStatus(order.id, DeliveryOrderStatus.outForDelivery);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order ${order.id} is now Out for Delivery! 🛵 (Local demo state)',
        ),
        backgroundColor: AppColors.oceanBlue,
      ),
    );
  }

  void _handleMarkCashReceived(DeliveryOrder order) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Cash Collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Did you receive cash from the customer for this order?',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tropicalYellowLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Exact Cash Due:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${AppConstants.currency}${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.tropicalYellowDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Note: This updates local demo state only. No real bank or accounting server is affected.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.limeGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              final state = StaffStateScope.read(context);
              state.markCashReceived(order.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Cash payment of \$${order.totalAmount.toStringAsFixed(2)} marked as received! 💵',
                  ),
                  backgroundColor: AppColors.limeGreenDark,
                ),
              );
            },
            child: const Text('Confirm Cash Received'),
          ),
        ],
      ),
    );
  }

  void _handleConfirmDelivered(DeliveryOrder order) async {
    // If order is COD and cash has NOT been marked received yet, give prompt
    if (order.requiresCashCollection) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('⚠️ Pending Cash Collection'),
          content: Text(
            'This order requires collecting \$${order.totalAmount.toStringAsFixed(2)} in cash.\n\nWould you like to mark cash as collected and finish delivery?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Collect Cash & Complete'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    if (!mounted) return;

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final state = StaffStateScope.read(context);
    if (order.orderType == 'pickup') {
      state.markOrderPickedUp(order.id);
    } else {
      state.markOrderDelivered(order.id);
    }

    setState(() => _isProcessing = false);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (successCtx) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.limeGreen,
          size: 48,
        ),
        title: Text(
          order.orderType == 'pickup'
              ? 'Pickup Completed!'
              : 'Delivery Completed!',
        ),
        content: Text(
          'Order ${order.id} has been successfully completed and moved to Delivery History.\n\n(Local demo state updated)',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(successCtx).pop();
                if (!mounted) return;
                Navigator.of(context).pop(); // Return to assigned list
              },
              child: const Text('Back to Assigned Orders'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = StaffStateScope.of(context);
    // Find active order or check history if completed
    final activeOrder = state.assignedOrders
        .where((o) => o.id == widget.orderId)
        .firstOrNull;
    final historyOrder = state.deliveryHistory
        .where((o) => o.id == widget.orderId)
        .firstOrNull;
    final order = activeOrder ?? historyOrder;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final isDelivered =
        order.status == DeliveryOrderStatus.delivered ||
        order.status == DeliveryOrderStatus.pickedUp;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order ${order.id}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: isDelivered
                  ? StatusChip.delivered()
                  : order.status == DeliveryOrderStatus.outForDelivery
                  ? StatusChip.outForDelivery()
                  : StatusChip.assigned(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DemoBanner(
                      label: 'LOCAL DEMO STATE • Actions update in-memory state only',
                    ),
                    const SizedBox(height: 8),

                    // Destination / Customer Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Customer & Destination',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, hh:mm a')
                                    .format(order.orderTime),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.surfaceVariant,
                                child: Icon(
                                  Icons.person_rounded,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.customerName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      order.customerPhone,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.phone_rounded,
                                  color: AppColors.limeGreenDark,
                                ),
                                tooltip: 'Call Customer (Demo)',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Simulated Call to ${order.customerPhone} 📞',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.pin_drop_rounded,
                                size: 20,
                                color: AppColors.tropicalYellowDark,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  order.deliveryAddress,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.3,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (order.deliveryNotes != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.notes_rounded,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Note: ${order.deliveryNotes!}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Order Items Breakdown Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Order Items',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                '${order.totalItemCount} items total',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.tropicalYellowLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.quantity}x',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.tropicalYellowDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        if (item.options != null)
                                          Text(
                                            item.options!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${AppConstants.currency}${item.totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 20),
                          _buildSummaryRow('Subtotal', order.subtotal),
                          _buildSummaryRow('Delivery Fee', order.deliveryFee),
                          _buildSummaryRow('Estimated Tax', order.tax),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total to Collect / Pay',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                '${AppConstants.currency}${order.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.tropicalYellowDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: order.requiresCashCollection
                            ? AppColors.warningOrangeLight.withValues(
                                alpha: 0.4,
                              )
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: order.requiresCashCollection
                              ? AppColors.warningOrange.withValues(alpha: 0.5)
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    order.requiresCashCollection
                                        ? Icons.payments_rounded
                                        : Icons.credit_card_rounded,
                                    size: 20,
                                    color: order.requiresCashCollection
                                        ? AppColors.warningOrange
                                        : AppColors.limeGreenDark,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    order.paymentMethod,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: order.requiresCashCollection
                                          ? AppColors.warningOrange
                                          : AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                              if (order.requiresCashCollection)
                                StatusChip.cashPending(
                                  amount: order.totalAmount,
                                )
                              else
                                StatusChip.paid(),
                            ],
                          ),
                          if (order.requiresCashCollection && !isDelivered) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Action Required: Collect cash payment upon arrival at customer address.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 10),
                            PrimaryButton(
                              text:
                                  'Mark Cash Received (\$${order.totalAmount.toStringAsFixed(2)})',
                              icon: Icons.check_circle_outline_rounded,
                              variant: ButtonVariant.success,
                              width: double.infinity,
                              onPressed: () => _handleMarkCashReceived(order),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Barcode & QR Verification Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              size: 28,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Customer Verification Pass',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Barcode: ${order.barcodeCode}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Delivery Action Buttons (if active)
            if (!isDelivered)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  children: [
                    if (order.status == DeliveryOrderStatus.assigned)
                      PrimaryButton(
                        text: 'Start Delivery / En Route',
                        icon: Icons.directions_bike_rounded,
                        variant: ButtonVariant.secondary,
                        width: double.infinity,
                        onPressed: () => _handleMarkOutForDelivery(order),
                      )
                    else
                      PrimaryButton(
                        text: order.orderType == 'pickup'
                            ? 'Complete Customer Pickup'
                            : 'Mark Order as Delivered',
                        icon: Icons.check_circle_rounded,
                        variant: ButtonVariant.success,
                        isLoading: _isProcessing,
                        width: double.infinity,
                        onPressed: () => _handleConfirmDelivered(order),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${AppConstants.currency}${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }
}
