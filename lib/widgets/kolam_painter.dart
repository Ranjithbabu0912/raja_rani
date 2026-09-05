import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// CustomPainter rendering subtle traditional Tamil Kolam corner accents tucked into corners
class KolamCornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const KolamCornerPainter({
    this.color = AppColors.terracotta,
    this.strokeWidth = 1.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 30 || size.height < 30) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    const double margin = 5.0;
    final double length = math.min(12.0, math.min(size.width, size.height) * 0.12);

    // Top-Left Corner
    final pathTL = Path()
      ..moveTo(margin, margin + length)
      ..lineTo(margin, margin)
      ..lineTo(margin + length, margin);
    canvas.drawPath(pathTL, paint);
    canvas.drawCircle(const Offset(margin + 4, margin + 4), 1.2, dotPaint);

    // Top-Right Corner
    final pathTR = Path()
      ..moveTo(size.width - margin - length, margin)
      ..lineTo(size.width - margin, margin)
      ..lineTo(size.width - margin, margin + length);
    canvas.drawPath(pathTR, paint);
    canvas.drawCircle(Offset(size.width - margin - 4, margin + 4), 1.2, dotPaint);

    // Bottom-Left Corner
    final pathBL = Path()
      ..moveTo(margin, size.height - margin - length)
      ..lineTo(margin, size.height - margin)
      ..lineTo(margin + length, size.height - margin);
    canvas.drawPath(pathBL, paint);
    canvas.drawCircle(Offset(margin + 4, size.height - margin - 4), 1.2, dotPaint);

    // Bottom-Right Corner
    final pathBR = Path()
      ..moveTo(size.width - margin - length, size.height - margin)
      ..lineTo(size.width - margin, size.height - margin)
      ..lineTo(size.width - margin, size.height - margin - length);
    canvas.drawPath(pathBR, paint);
    canvas.drawCircle(Offset(size.width - margin - 4, size.height - margin - 4), 1.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CustomPainter rendering a 8-petaled traditional Tamil Kolam / Lotus mandala
class KolamMandalaPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  const KolamMandalaPainter({
    this.primaryColor = AppColors.terracotta,
    this.secondaryColor = AppColors.turmeric,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final paintStroke = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final paintAccent = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final paintDot = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Draw central circle
    canvas.drawCircle(center, radius * 0.28, paintStroke);

    // Draw 8 Kolam Petals
    for (int i = 0; i < 8; i++) {
      final double angle = (i * math.pi / 4);
      final double petalRadius = radius * 0.72;

      final pX = center.dx + math.cos(angle) * petalRadius;
      final pY = center.dy + math.sin(angle) * petalRadius;

      // Draw petal arc loop
      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.quadraticBezierTo(
        center.dx + math.cos(angle - 0.3) * (petalRadius * 0.7),
        center.dy + math.sin(angle - 0.3) * (petalRadius * 0.7),
        pX,
        pY,
      );
      path.quadraticBezierTo(
        center.dx + math.cos(angle + 0.3) * (petalRadius * 0.7),
        center.dy + math.sin(angle + 0.3) * (petalRadius * 0.7),
        center.dx,
        center.dy,
      );
      canvas.drawPath(path, paintStroke);

      // Draw decorative dot at petal tip
      canvas.drawCircle(Offset(pX, pY), 2.0, paintDot);
    }

    // Outer geometric ring
    canvas.drawCircle(center, radius * 0.9, paintAccent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
