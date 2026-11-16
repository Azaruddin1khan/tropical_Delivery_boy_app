import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

/// A modern interactive "Swipe to Deliver" slider button styled to match the Tropical Gyros theme:
/// - Rounded pill container with brand lime green gradient
/// - Centered bold "Delivered" label that gently fades on swipe
/// - Circular white draggable handle with '>' chevron in theme color
/// - Spring-back physics if released early (<75%)
/// - Heavy haptic vibration & instant delivery confirmation on full swipe
class SwipeToDeliverButton extends StatefulWidget {
  final VoidCallback onDelivered;
  final String label;
  final double height;
  final List<Color>? gradientColors;
  final Color thumbColor;
  final Color? iconColor;

  const SwipeToDeliverButton({
    super.key,
    required this.onDelivered,
    this.label = 'Delivered',
    this.height = 54.0,
    this.gradientColors,
    this.thumbColor = Colors.white,
    this.iconColor,
  });

  @override
  State<SwipeToDeliverButton> createState() => _SwipeToDeliverButtonState();
}

class _SwipeToDeliverButtonState extends State<SwipeToDeliverButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _resetAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _dragPosition = _resetAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isCompleted) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (_isCompleted) return;
    if (_dragPosition >= maxDrag * 0.75) {
      // Confirmed delivery!
      setState(() {
        _isCompleted = true;
        _dragPosition = maxDrag;
      });
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          widget.onDelivered();
        }
      });
    } else {
      // Spring back to start
      _resetAnimation = Tween<double>(
        begin: _dragPosition,
        end: 0.0,
      ).animate(
        CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
      );
      _resetController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme-matched gradient (Vibrant Emerald / Lime Green)
    final colors = widget.gradientColors ??
        const [
          Color(0xFF22C55E),
          AppColors.limeGreen,
          AppColors.limeGreenDark,
        ];

    final chevronColor = widget.iconColor ?? AppColors.limeGreenDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final thumbSize = widget.height - 8;
        final maxDrag = (totalWidth - thumbSize - 8).clamp(0.0, totalWidth);
        final progress = maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        return GestureDetector(
          // Allow swiping across the whole pill track as well
          onHorizontalDragUpdate: (details) => _onDragUpdate(details, maxDrag),
          onHorizontalDragEnd: (details) => _onDragEnd(details, maxDrag),
          child: Container(
            height: widget.height,
            width: totalWidth,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(widget.height / 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.limeGreen.withValues(alpha: 0.38),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Center Label (Gently fades as slider moves across)
                Center(
                  child: Opacity(
                    opacity: (1.0 - (progress * 1.3)).clamp(0.0, 1.0),
                    child: Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),

                // Draggable circular thumb
                Positioned(
                  left: 4 + _dragPosition,
                  top: 4,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: widget.thumbColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isCompleted ? Icons.check_rounded : Icons.chevron_right_rounded,
                        color: chevronColor,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
