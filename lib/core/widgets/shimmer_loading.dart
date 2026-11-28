import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A high-performance, 60 FPS sweeping gradient shimmer effect.
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE2E8F0), // slate-200
    this.highlightColor = const Color(0xFFF8FAFC), // slate-50
    this.duration = const Duration(milliseconds: 1300),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-2.2 + _controller.value * 4.4, -0.3),
              end: Alignment(-0.2 + _controller.value * 4.4, 0.3),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// A basic placeholder box that shimmer can wrap.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final Color? color;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE2E8F0),
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer placeholder mimicking an Assigned Order Card
class OrderCardShimmer extends StatelessWidget {
  const OrderCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: ID, tag & timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const ShimmerBox(width: 85, height: 18, borderRadius: 6),
                    const SizedBox(width: 8),
                    const ShimmerBox(width: 60, height: 16, borderRadius: 6),
                  ],
                ),
                const ShimmerBox(width: 55, height: 14, borderRadius: 4),
              ],
            ),
            const SizedBox(height: 12),

            // Customer Name
            Row(
              children: [
                const ShimmerBox(
                  width: 32,
                  height: 32,
                  shape: BoxShape.circle,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerBox(width: 130, height: 14, borderRadius: 4),
                      const SizedBox(height: 6),
                      const ShimmerBox(width: 90, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
                const ShimmerBox(width: 70, height: 22, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 12),

            // Delivery Address placeholder
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 16, height: 16, borderRadius: 4),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerBox(
                        width: double.infinity,
                        height: 12,
                        borderRadius: 4,
                      ),
                      const SizedBox(height: 5),
                      const ShimmerBox(width: 180, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Item count & Total amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ShimmerBox(width: 120, height: 13, borderRadius: 4),
                const ShimmerBox(width: 75, height: 18, borderRadius: 4),
              ],
            ),
            const SizedBox(height: 14),

            // Bottom Buttons
            Row(
              children: [
                Expanded(
                  child: const ShimmerBox(height: 40, borderRadius: 10),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: const ShimmerBox(height: 40, borderRadius: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for Delivery History Card
class HistoryCardShimmer extends StatelessWidget {
  const HistoryCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
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
                const ShimmerBox(width: 90, height: 16, borderRadius: 6),
                const ShimmerBox(width: 70, height: 18, borderRadius: 8),
              ],
            ),
            const SizedBox(height: 10),
            const ShimmerBox(width: 140, height: 14, borderRadius: 4),
            const SizedBox(height: 6),
            const ShimmerBox(width: 200, height: 12, borderRadius: 4),
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ShimmerBox(width: 100, height: 12, borderRadius: 4),
                const ShimmerBox(width: 65, height: 16, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for Order Details Screen
class OrderDetailsShimmer extends StatelessWidget {
  const OrderDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar
            const ShimmerBox(width: double.infinity, height: 60, borderRadius: 14),
            const SizedBox(height: 16),

            // Customer Card
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
                  const ShimmerBox(width: 130, height: 16, borderRadius: 4),
                  const SizedBox(height: 12),
                  const ShimmerBox(width: 160, height: 14, borderRadius: 4),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
                  const SizedBox(height: 6),
                  const ShimmerBox(width: 180, height: 12, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ShimmerBox(width: 140, height: 14, borderRadius: 4),
                      const ShimmerBox(width: 50, height: 14, borderRadius: 4),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ShimmerBox(width: 110, height: 14, borderRadius: 4),
                      const ShimmerBox(width: 50, height: 14, borderRadius: 4),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ShimmerBox(width: 60, height: 16, borderRadius: 4),
                      const ShimmerBox(width: 80, height: 18, borderRadius: 4),
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
