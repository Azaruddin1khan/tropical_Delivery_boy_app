import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/primary_button.dart';
import '../core/widgets/shimmer_loading.dart';
import '../core/widgets/status_chip.dart';
import '../models/delivery_order.dart';
import '../state/staff_state_scope.dart';
import 'barcode_scanner_screen.dart';
import 'delivery_route_map_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isProcessing = false;

  Future<String?> _showPaymentMethodDialog(
    BuildContext context,
    double amount,
  ) {
    String selected = 'cash';
    return showDialog<String>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.point_of_sale_rounded, color: AppColors.oceanBlue),
              SizedBox(width: 8),
              Text(
                'Doorstep Payment',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      'Amount to Collect:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      '${AppConstants.currency}${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.tropicalYellowDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Select payment method received from customer:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),

              // 1. Cash option
              InkWell(
                onTap: () => setDialogState(() => selected = 'cash'),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: selected == 'cash' ? const Color(0xFFECFDF5) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected == 'cash' ? AppColors.limeGreen : const Color(0xFFCBD5E1),
                      width: selected == 'cash' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payments_rounded, color: Color(0xFF059669), size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cash (Remit at Store)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            Text(
                              'Physical cash collected',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected == 'cash'
                                ? AppColors.limeGreenDark
                                : const Color(0xFF94A3B8),
                            width: selected == 'cash' ? 6 : 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Credit Card (POS)
              InkWell(
                onTap: () => setDialogState(() => selected = 'credit_card'),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: selected == 'credit_card' ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected == 'credit_card' ? AppColors.oceanBlue : const Color(0xFFCBD5E1),
                      width: selected == 'credit_card' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card_rounded, color: AppColors.oceanBlue, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Credit Card (POS Machine)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            Text(
                              'Charged on card machine',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected == 'credit_card'
                                ? AppColors.oceanBlue
                                : const Color(0xFF94A3B8),
                            width: selected == 'credit_card' ? 6 : 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Debit Card (POS)
              InkWell(
                onTap: () => setDialogState(() => selected = 'debit_card'),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected == 'debit_card' ? const Color(0xFFF5F3FF) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected == 'debit_card' ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
                      width: selected == 'debit_card' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_score_rounded, color: Color(0xFF7C3AED), size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Debit Card (POS Machine)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            Text(
                              'Charged on card machine',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected == 'debit_card'
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF94A3B8),
                            width: selected == 'debit_card' ? 6 : 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(selected),
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMarkCashReceived(DeliveryOrder order) async {
    final chosenMethod = await _showPaymentMethodDialog(
      context,
      order.totalAmount,
    );
    if (chosenMethod == null || !mounted) return;

    final state = StaffStateScope.read(context);
    state.markCashReceived(order.id, paymentMethod: chosenMethod);

    final methodLabel = chosenMethod == 'credit_card'
        ? 'Credit Card (POS)'
        : (chosenMethod == 'debit_card' ? 'Debit Card (POS)' : 'Cash');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment of ${AppConstants.currency}${order.totalAmount.toStringAsFixed(2)} recorded via $methodLabel! 💵💳',
        ),
        backgroundColor: AppColors.limeGreenDark,
      ),
    );
  }

  void _handleConfirmDelivered(DeliveryOrder order) async {
    String? chosenMethod;
    // If order is COD and payment has NOT been marked received yet, prompt for payment method
    if (order.requiresCashCollection) {
      chosenMethod = await _showPaymentMethodDialog(
        context,
        order.totalAmount,
      );
      if (chosenMethod == null) return;
    }

    if (!mounted) return;

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final state = StaffStateScope.read(context);
    if (order.orderType == 'pickup') {
      state.markOrderPickedUp(order.id);
    } else {
      state.markOrderDelivered(order.id, paymentMethod: chosenMethod);
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
      if (state.isLoadingOrders) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: Text('Order #${widget.orderId}')),
          body: const SafeArea(child: OrderDetailsShimmer()),
        );
      }
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
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.oceanBlue,
                                side: const BorderSide(
                                  color: AppColors.oceanBlue,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              icon: const Icon(
                                Icons.navigation_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                '🛰️ Open Live GPS Navigation Map',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DeliveryRouteMapScreen(order: order),
                                  ),
                                );
                              },
                            ),
                          ),
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
                                    order.paymentMethodDisplay,
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
                              'Action Required: Collect payment (Cash or POS Card Machine) upon arrival at customer address.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 10),
                            PrimaryButton(
                              text:
                                  'Record Doorstep Payment (${AppConstants.currency}${order.totalAmount.toStringAsFixed(2)})',
                              icon: Icons.point_of_sale_rounded,
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
                    if (order.status == DeliveryOrderStatus.assigned) ...[
                      PrimaryButton(
                        text: 'Scan Kitchen Bag to Pickup',
                        icon: Icons.qr_code_scanner_rounded,
                        variant: ButtonVariant.primary,
                        width: double.infinity,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BarcodeScannerScreen(
                                targetOrderCode: order.barcodeCode,
                              ),
                            ),
                          );
                        },
                      ),
                    ] else if (order.orderType == 'pickup')
                      PrimaryButton(
                        text: 'Complete Customer Pickup',
                        icon: Icons.check_circle_rounded,
                        variant: ButtonVariant.success,
                        isLoading: _isProcessing,
                        width: double.infinity,
                        onPressed: () => _handleConfirmDelivered(order),
                      )
                    else ...[
                      PrimaryButton(
                        text: 'Scan Customer Drop Pass',
                        icon: Icons.qr_code_scanner_rounded,
                        variant: ButtonVariant.success,
                        width: double.infinity,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BarcodeScannerScreen(
                                targetOrderCode: order.customerDropCode,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.navigation_rounded, size: 18),
                        label: const Text('Open Live Navigation Map 🛵'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.oceanBlue,
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: AppColors.oceanBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DeliveryRouteMapScreen(order: order),
                            ),
                          );
                        },
                      ),
                    ],
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
