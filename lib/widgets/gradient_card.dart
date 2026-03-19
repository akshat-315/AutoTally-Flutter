import 'package:flutter/material.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final Gradient? borderGradient;
  final double borderWidth;
  final double borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GradientCard({
    super.key,
    required this.child,
    this.borderGradient,
    this.borderWidth = 1,
    this.borderRadius = 16,
    this.backgroundColor,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).colorScheme.surface;

    if (borderGradient == null) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        padding: padding,
        child: child,
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: borderGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlowContainer({
    super.key,
    required this.child,
    required this.glowColor,
    this.glowRadius = 24,
    this.borderRadius = 16,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.15),
            blurRadius: glowRadius,
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: glowColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}
