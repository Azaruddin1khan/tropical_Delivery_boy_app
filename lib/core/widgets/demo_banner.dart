import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DemoBanner extends StatelessWidget {
  final String label;

  const DemoBanner({
    super.key,
    this.label = 'DEMO UI ONLY • Local State • No Backend/API',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.tropicalYellowLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.tropicalYellowDark.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: AppColors.tropicalYellowDark,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.tropicalYellowDark,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
