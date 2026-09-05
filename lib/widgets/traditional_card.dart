import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'kolam_painter.dart';

/// Reusable container widget providing traditional Tamil function/invitation card styling
class TraditionalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final bool showKolamCorners;
  final VoidCallback? onTap;

  const TraditionalCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.backgroundColor = AppColors.cardCream,
    this.borderColor = AppColors.terracotta,
    this.borderWidth = 1.5,
    this.showKolamCorners = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppDecorations.traditionalCard(
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        borderWidth: borderWidth,
        borderRadius: borderRadius,
      ),
      child: showKolamCorners
          ? CustomPaint(
              painter: KolamCornerPainter(color: borderColor),
              child: child,
            )
          : child,
    );

    if (margin != null) {
      cardContent = Padding(padding: margin!, child: cardContent);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
