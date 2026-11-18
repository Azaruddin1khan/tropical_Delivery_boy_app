import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

/// A modern interactive "Swipe to Deliver" slider button styled to match the Tropical Gyros theme:
/// - Rounded pill container with brand lime green gradient (or slate/locked gradient when disabled)
/// - Centered bold "Delivered" label that gently fades on swipe
/// - Circular white draggable handle with '>' chevron in theme color (or lock icon when disabled)
/// - Spring-back physics if released early (<75%)
/// - Heavy haptic vibration & instant delivery confirmation on full swipe
/// - Strict Doorstep Geofence Support: When `enabled: false`, locks sliding and prompts the courier
class SwipeToDeliverButton extends StatefulWidget {
  final VoidCallback onDelivered;
  final String label;
  final double height;
  final List<Color>? gradientColors;
  final Color thumbColor;
  final Color? iconColor;
  final bool enabled;
  final String? disabledLabel;
  final VoidCallback? onDisabledTap;

  const SwipeToDeliverButton({
    super.key,
    required this.onDelivered,
    this.label = 'Delivered',
    this.height = 54.0,
    this.gradientColors,
    this.thumbColor = Colors.white,
    this.iconColor,
    this.enabled = true,
    this.disabledLabel,
    this.onDisabledTap,
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
    _resetAnimation =
        Tween<double>(begin: 0, end: 0).animate(
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
    if (!widget.enabled) {
      return;
    }
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (_isCompleted) return;
    if (!widget.enabled) {
      widget.onDisabledTap?.call();
      return;
    }
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
      _resetAnimation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
      );
      _resetController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.enabled;

    // Active Emerald / Lime Green gradient vs Locked Slate gradient
    final colors = !isEnabled
        ? const [Color(0xFF334155), Color(0xFF475569), Color(0xFF334155)]
        : (widget.gradientColors ??
              const [
                Color(0xFF22C55E),
                AppColors.limeGreen,
                AppColors.limeGreenDark,
              ]);

    final chevronColor = !isEnabled
        ? const Color(0xFF64748B)
        : (widget.iconColor ?? AppColors.limeGreenDark);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final thumbSize = widget.height - 8;
        final maxDrag = (totalWidth - thumbSize - 8).clamp(0.0, totalWidth);
        final progress = maxDrag > 0
            ? (_dragPosition / maxDrag).clamp(0.0, 1.0)
            : 0.0;

        return GestureDetector(
          onTap: () {
            if (!isEnabled) {
              HapticFeedback.selectionClick();
              widget.onDisabledTap?.call();
            }
          },
          // Allow swiping across the whole pill track
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
              border: !isEnabled
                  ? Border.all(color: const Color(0xFF64748B), width: 1.2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isEnabled
                      ? AppColors.limeGreen.withValues(alpha: 0.38)
                      : Colors.black.withValues(alpha: 0.15),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isEnabled) ...[
                          const Icon(
                            Icons.lock_rounded,
                            size: 16,
                            color: Color(0xFFCBD5E1),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            isEnabled
                                ? widget.label
                                : (widget.disabledLabel ??
                                      'Reach drop location to deliver'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isEnabled
                                  ? Colors.white
                                  : const Color(0xFFE2E8F0),
                              fontSize: isEnabled ? 16.5 : 14.0,
                              fontWeight: isEnabled
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
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
                        _isCompleted
                            ? Icons.check_rounded
                            : (!isEnabled
                                  ? Icons.lock_outline_rounded
                                  : Icons.chevron_right_rounded),
                        color: chevronColor,
                        size: isEnabled ? 28 : 22,
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
