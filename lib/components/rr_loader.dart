import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Authentic Notebook-Paper Concept Loading Animation
/// (Completely replaces old spinning ring/Kolam loader with theme-matched paper chit)
class RRLoader extends StatefulWidget {
  final String? message;
  final double size;
  final bool fullScreen;

  const RRLoader({
    super.key,
    this.message,
    this.size = 70.0,
    this.fullScreen = false,
  });

  @override
  State<RRLoader> createState() => _RRLoaderState();
}

class _RRLoaderState extends State<RRLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildNotebookPaperLoader() {
    final double scale = (widget.size / 70.0).clamp(0.6, 1.5);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final floatOffset = math.sin(_controller.value * 2 * math.pi) * 4.0;
        final penXOffset = math.sin(_controller.value * 2 * math.pi) * 16.0;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notebook Paper Logo Chit Container
              Container(
                width: 120 * scale,
                height: 85 * scale,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8 * scale,
                      offset: Offset(2 * scale, 4 * scale),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _NotebookPaperLoaderPainter(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Handwritten Logo Title
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'RAJA RANI',
                            style: TextStyle(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5 * scale,
                              color: AppColors.ballpointBlue,
                            ),
                          ),
                          SizedBox(height: 2 * scale),
                          Container(
                            width: 60 * scale,
                            height: 1.5 * scale,
                            color: AppColors.blueRuling.withValues(alpha: 0.8),
                          ),
                        ],
                      ),

                      // Animated Ballpoint Pen Nib writing across logo
                      Positioned(
                        right: (14 * scale) + penXOffset,
                        bottom: 12 * scale,
                        child: Icon(
                          Icons.edit,
                          size: 16 * scale,
                          color: AppColors.ballpointBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNotebookPaperLoader(),
        if (widget.message != null && widget.message!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlack,
              letterSpacing: 0.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );

    if (widget.fullScreen) {
      return Scaffold(
        backgroundColor: AppColors.warmPaper,
        body: Center(child: content),
      );
    }

    return Center(child: content);
  }
}

/// Custom Painter for the Notebook Paper Logo Loading Chit
class _NotebookPaperLoaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;

    // Irregular torn notebook paper edges
    path.moveTo(0, 0);
    for (double x = 0; x < w; x += 6) {
      final dy = (x % 12 == 0) ? -1.0 : 0.8;
      path.lineTo(x + 3, dy);
    }
    path.lineTo(w, 0);

    for (double y = 0; y < h; y += 6) {
      final dx = (y % 12 == 0) ? w + 1.0 : w - 0.8;
      path.lineTo(dx, y + 3);
    }
    path.lineTo(w, h);

    path.lineTo(0, h);

    for (double y = h; y > 0; y -= 6) {
      final dx = (y % 12 == 0) ? -1.0 : 0.8;
      path.lineTo(dx, y - 3);
    }
    path.close();

    // Fill Warm Notebook Paper Body
    final paperPaint = Paint()
      ..color = const Color(0xFFFFFDF8)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paperPaint);

    // Blue horizontal ruling lines
    final bluePaint = Paint()
      ..color = AppColors.blueRuling.withValues(alpha: 0.65)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (double y = 14; y < h - 4; y += 14) {
      canvas.drawLine(Offset(4, y), Offset(w - 4, y), bluePaint);
    }

    // Red vertical margin line
    final redPaint = Paint()
      ..color = AppColors.redMargin.withValues(alpha: 0.6)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(14, 0), Offset(14, h), redPaint);

    // Outer notebook border stroke
    final strokePaint = Paint()
      ..color = AppColors.blueRuling.withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

