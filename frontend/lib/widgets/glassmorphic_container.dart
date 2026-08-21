import 'dart:ui';
import 'package:flutter/material.dart';
import 'theme.dart';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool isDark;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = GlintTheme.radiusMd,
    this.blurSigma = 30.0,
    this.color,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: GlintTheme.glassDecoration(
        isDark: isDark,
        borderRadius: borderRadius,
        color: color,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(GlintTheme.gutter),
            child: child,
          ),
        ),
      ),
    );
  }
}
