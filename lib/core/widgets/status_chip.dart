import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusChip.assigned() {
    return const StatusChip(
      label: 'Assigned',
      backgroundColor: AppColors.oceanBlueLight,
      textColor: AppColors.oceanBlueDark,
      icon: Icons.assignment_outlined,
    );
  }

  factory StatusChip.outForDelivery() {
    return const StatusChip(
      label: 'Out for Delivery',
      backgroundColor: AppColors.tropicalYellowLight,
      textColor: AppColors.tropicalYellowDark,
      icon: Icons.delivery_dining_rounded,
    );
  }

  factory StatusChip.delivered() {
    return const StatusChip(
      label: 'Delivered',
      backgroundColor: AppColors.limeGreenLight,
      textColor: AppColors.limeGreenDark,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  factory StatusChip.paid() {
    return const StatusChip(
      label: 'Paid Online',
      backgroundColor: AppColors.limeGreenLight,
      textColor: AppColors.limeGreenDark,
      icon: Icons.credit_card_rounded,
    );
  }

  factory StatusChip.cashPending({required double amount}) {
    return StatusChip(
      label: 'Collect Cash: \$${amount.toStringAsFixed(2)}',
      backgroundColor: AppColors.warningOrangeLight,
      textColor: AppColors.warningOrange,
      icon: Icons.payments_outlined,
    );
  }

  factory StatusChip.cashCollected() {
    return const StatusChip(
      label: 'Cash Collected',
      backgroundColor: AppColors.limeGreenLight,
      textColor: AppColors.limeGreenDark,
      icon: Icons.task_alt_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
