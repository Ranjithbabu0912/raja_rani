import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Reusable Hand-drawn Pen Marks and Annotations for Raja Rani Notebook Theme.

/// 1. Hand-Drawn Pen Circle around selected text / player name
class HandwrittenCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  HandwrittenCirclePainter({
    this.color = AppColors.ballpointBlue,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final rx = size.width / 2;
    final ry = size.height / 2;

    // Slight hand-drawn oval imbalance
    path.addOval(Rect.fromLTRB(
      2,
      2,
      size.width - 2,
      size.height - 2,
    ));

    canvas.drawPath(path, paint);

    // Overlapping end stroke for realistic hand-drawn pen circle
    final extraPath = Path()
      ..moveTo(size.width - 6, 8)
      ..cubicTo(size.width + 2, ry, rx, size.height - 1, 6, size.height - 4);
    canvas.drawPath(extraPath, paint..strokeWidth = strokeWidth * 0.8);
  }

  @override
  bool shouldRepaint(covariant HandwrittenCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// 2. Hand-Drawn Pen Underline
class HandwrittenUnderlinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  HandwrittenUnderlinePainter({
    this.color = AppColors.ballpointBlue,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height - 2);
    path.cubicTo(
      size.width * 0.3,
      size.height + 1,
      size.width * 0.7,
      size.height - 4,
      size.width,
      size.height - 1,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HandwrittenUnderlinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// 3. Hand-Drawn Pen Checkmark (✓)
class HandwrittenCheckMark extends StatelessWidget {
  final Color color;
  final double size;

  const HandwrittenCheckMark({
    super.key,
    this.color = AppColors.penGreen,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CheckMarkPainter(color: color),
    );
  }
}

class _CheckMarkPainter extends CustomPainter {
  final Color color;

  _CheckMarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.55);
    path.lineTo(size.width * 0.42, size.height * 0.85);
    path.lineTo(size.width * 0.88, size.height * 0.18);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 4. Hand-Drawn Pen Wrong Cross (✕)
class HandwrittenCrossMark extends StatelessWidget {
  final Color color;
  final double size;

  const HandwrittenCrossMark({
    super.key,
    this.color = AppColors.terracotta,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CrossMarkPainter(color: color),
    );
  }
}

class _CrossMarkPainter extends CustomPainter {
  final Color color;

  _CrossMarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.8),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.2, size.height * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CrossMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 5. Hand-Drawn Pen Exchange Arrow (↕)
class HandwrittenExchangeArrow extends StatelessWidget {
  final Color color;
  final double height;

  const HandwrittenExchangeArrow({
    super.key,
    this.color = AppColors.terracotta,
    this.height = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(24, height),
      painter: _ExchangeArrowPainter(color: color),
    );
  }
}

class _ExchangeArrowPainter extends CustomPainter {
  final Color color;

  _ExchangeArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;

    // Vertical line
    canvas.drawLine(Offset(cx, 4), Offset(cx, size.height - 4), paint);

    // Top arrow cap
    canvas.drawLine(Offset(cx - 6, 10), Offset(cx, 4), paint);
    canvas.drawLine(Offset(cx + 6, 10), Offset(cx, 4), paint);

    // Bottom arrow cap
    canvas.drawLine(Offset(cx - 6, size.height - 10), Offset(cx, size.height - 4), paint);
    canvas.drawLine(Offset(cx + 6, size.height - 10), Offset(cx, size.height - 4), paint);
  }

  @override
  bool shouldRepaint(covariant _ExchangeArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 6. Notebook Ink Button
class NotebookInkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color inkColor;
  final Color textColor;
  final Color? borderColor;
  final bool isLoading;
  final IconData? icon;

  const NotebookInkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.inkColor = AppColors.ballpointBlue,
    this.textColor = Colors.white,
    this.borderColor,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;
    final Color borderC =
        borderColor ?? (enabled ? inkColor : Colors.grey.shade500);

    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? inkColor : Colors.grey.shade300,
          foregroundColor: enabled ? textColor : Colors.grey.shade600,
          elevation: enabled ? 1 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: borderC,
              width: 2.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: enabled ? onPressed : null,
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: textColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: AppTypography.handwrittenTitle(
                      fontSize: 16,
                      letterSpacing: 1.2,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
