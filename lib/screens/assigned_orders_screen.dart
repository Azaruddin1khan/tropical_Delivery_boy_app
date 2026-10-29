import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/demo_banner.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/status_chip.dart';
import '../models/delivery_order.dart';
import '../state/staff_state_scope.dart';
import 'order_details_screen.dart';

class AssignedOrdersScreen extends StatefulWidget {
  const AssignedOrdersScreen({super.key});

  @override
  State<AssignedOrdersScreen> createState() => _AssignedOrdersScreenState();
}

class _AssignedOrdersScreenState extends State<AssignedOrdersScreen> {
  String _selectedFilter = 'all'; // 'all', 'outForDelivery', 'cod'

  @override
  Widget build(BuildContext context) {
    final state = StaffStateScope.of(context);
    final allOrders = state.assignedOrders;

    final filteredOrders = allOrders.where((order) {
      if (_selectedFilter == 'outForDelivery') {
        return order.status == DeliveryOrderStatus.outForDelivery;
      }
      if (_selectedFilter == 'cod') {
        return order.requiresCashCollection;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  const DemoBanner(
                    label: 'ASSIGNED DELIVERIES • Tap any order to process actions',
                  ),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'All Active (${allOrders.length})',
                          key: 'all',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label:
                              'En Route (${allOrders.where((o) => o.status == DeliveryOrderStatus.outForDelivery).length})',
                          key: 'outForDelivery',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label:
                              '⚠️ Collect Cash (${allOrders.where((o) => o.requiresCashCollection).length})',
                          key: 'cod',
                          highlight: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: filteredOrders.isEmpty
                  ? EmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'No Assigned Orders Found',
                      message: _selectedFilter == 'all'
                          ? 'You have completed all active assigned deliveries!\nReady for new dispatches.'
                          : 'No orders match the selected filter criteria.',
                      actionLabel: _selectedFilter != 'all'
                          ? 'Show All Orders'
                          : null,
                      onAction: _selectedFilter != 'all'
                          ? () => setState(() => _selectedFilter = 'all')
                          : null,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filteredOrders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return _buildOrderCard(context, order);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String key,
    bool highlight = false,
  }) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = key),
      selectedColor: highlight
          ? AppColors.warningOrangeLight
          : AppColors.tropicalYellowLight,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? (highlight ? AppColors.warningOrange : AppColors.textDark)
            : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected
            ? (highlight
                  ? AppColors.warningOrange
                  : AppColors.tropicalYellowDark)
            : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildOrderCard(BuildContext context, DeliveryOrder order) {
    final timeStr = DateFormat('hh:mm a').format(order.orderTime);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(orderId: order.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: order.requiresCashCollection
                ? AppColors.warningOrange.withValues(alpha: 0.4)
                : AppColors.border,
            width: order.requiresCashCollection ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Order ID, Type & Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      order.id,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: order.orderType == 'pickup'
                            ? AppColors.oceanBlueLight
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.orderType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: order.orderType == 'pickup'
                              ? AppColors.oceanBlueDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Customer Name & Destination Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  order.orderType == 'pickup'
                      ? Icons.storefront_rounded
                      : Icons.location_on_rounded,
                  size: 18,
                  color: order.orderType == 'pickup'
                      ? AppColors.oceanBlue
                      : AppColors.tropicalYellowDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.deliveryAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item summary snippet
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.fastfood_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${order.totalItemCount} items • ${order.items.map((i) => "${i.quantity}x ${i.name}").join(', ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),

            // Bottom Row: Price, Payment Status & Action Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '${AppConstants.currency}${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (order.requiresCashCollection)
                      StatusChip.cashPending(amount: order.totalAmount)
                    else
                      StatusChip.paid(),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
