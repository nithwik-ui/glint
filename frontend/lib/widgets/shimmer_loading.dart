import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'theme.dart';

class ShimmerLoading extends StatelessWidget {
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.height,
    this.borderRadius = GlintTheme.radiusDefault,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E172A) : const Color(0xFFEADBEE),
      highlightColor: isDark ? const Color(0xFF2C223E) : const Color(0xFFF3E8F5),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerGridLoading extends StatelessWidget {
  const ShimmerGridLoading({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate heights of different card sizes for staggered grid mockup
    final heights = [280.0, 320.0, 240.0, 380.0, 260.0, 340.0];
    
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: GlintTheme.gutter,
        mainAxisSpacing: GlintTheme.gutter,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        final height = heights[index % heights.length];
        return ShimmerLoading(height: height);
      },
    );
  }
}
