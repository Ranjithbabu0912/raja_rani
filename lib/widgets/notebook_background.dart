import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Reusable Indian School/College Notebook Paper Background widget.
/// Renders warm paper background (#F7F1DF), horizontal blue ruled lines (#B8CFE3),
/// vertical red margin line (#D58A82), and subtle paper grain.
class NotebookBackground extends StatelessWidget {
  final Widget child;
  final double lineSpacing;
  final double marginOffset;
  final bool showMargin;

  const NotebookBackground({
    super.key,
    required this.child,
    this.lineSpacing = 28.0,
    this.marginOffset = 44.0,
    this.showMargin = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmPaper,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _NotebookPaperPainter(
                lineSpacing: lineSpacing,
                marginOffset: marginOffset,
                showMargin: showMargin,
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(child: child),
          ),
        ],
      ),
    );
  }
}

class _NotebookPaperPainter extends CustomPainter {
  final double lineSpacing;
  final double marginOffset;
  final bool showMargin;

  _NotebookPaperPainter({
    required this.lineSpacing,
    required this.marginOffset,
    required this.showMargin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Warm notebook paper background
    final bgPaint = Paint()..color = AppColors.warmPaper;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Horizontal blue ruled lines
    final blueLinePaint = Paint()
      ..color = AppColors.blueRuling
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double y = lineSpacing;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), blueLinePaint);
      y += lineSpacing;
    }

    // 3. Double Vertical Red Margin Line
    if (showMargin) {
      final redMarginPaint = Paint()
        ..color = AppColors.redMargin
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      // Primary margin line
      canvas.drawLine(
        Offset(marginOffset, 0),
        Offset(marginOffset, size.height),
        redMarginPaint,
      );

      // Secondary subtle double margin line (classic notebook feature)
      canvas.drawLine(
        Offset(marginOffset - 4, 0),
        Offset(marginOffset - 4, size.height),
        Paint()
          ..color = AppColors.redMargin.withValues(alpha: 0.4)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NotebookPaperPainter oldDelegate) {
    return oldDelegate.lineSpacing != lineSpacing ||
        oldDelegate.marginOffset != marginOffset ||
        oldDelegate.showMargin != showMargin;
  }
}
