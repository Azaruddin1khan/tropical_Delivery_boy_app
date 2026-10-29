import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum ButtonVariant { primary, success, secondary, outline, danger }

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonVariant variant;
  final bool isLoading;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case ButtonVariant.primary:
        bg = AppColors.tropicalYellow;
        fg = AppColors.textDark;
        break;
      case ButtonVariant.success:
        bg = AppColors.limeGreen;
        fg = Colors.white;
        break;
      case ButtonVariant.secondary:
        bg = AppColors.oceanBlue;
        fg = Colors.white;
        break;
      case ButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.textDark;
        border = const BorderSide(color: AppColors.border, width: 1.5);
        break;
      case ButtonVariant.danger:
        bg = AppColors.errorRed;
        fg = Colors.white;
        break;
    }

    return SizedBox(
      width: width,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: border,
          ),
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textMuted,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
