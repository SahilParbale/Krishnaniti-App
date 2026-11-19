import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Lightweight, 60fps pulsing skeleton shimmer card matching Tailwind card styling.
/// Used during data fetching, page switching, and filter updates.
class AppShimmerCard extends StatefulWidget {
  final double height;
  final double? width;
  final EdgeInsetsGeometry margin;
  final BorderRadius? borderRadius;

  const AppShimmerCard({
    super.key,
    this.height = 80,
    this.width,
    this.margin = const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    this.borderRadius,
  });

  @override
  State<AppShimmerCard> createState() => _AppShimmerCardState();
}

class _AppShimmerCardState extends State<AppShimmerCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.45, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          margin: widget.margin,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: radius,
            border: Border.all(color: AppColors.slate200),
          ),
          child: Opacity(
            opacity: _animation.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.slate200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: 140,
                            decoration: BoxDecoration(
                              color: AppColors.slate200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 10,
                            width: 90,
                            decoration: BoxDecoration(
                              color: AppColors.slate100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer list placeholder displaying multiple skeleton cards
class AppShimmerList extends StatelessWidget {
  final int count;
  final double cardHeight;
  final EdgeInsetsGeometry padding;

  const AppShimmerList({
    super.key,
    this.count = 6,
    this.cardHeight = 84,
    this.padding = const EdgeInsets.only(top: 8, bottom: 80),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: padding,
      itemCount: count,
      itemBuilder: (context, index) => AppShimmerCard(height: cardHeight),
    );
  }
}
