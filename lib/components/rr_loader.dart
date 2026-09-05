import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/kolam_painter.dart';

/// Traditional Tamil Kolam Lotus Mandala Loader Component
/// (Completely removes old RR text loader)
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
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildTraditionalKolamLoader() {
    final double totalSize = widget.size + 24;

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer spinning terracotta ring
          RotationTransition(
            turns: _controller,
            child: SizedBox(
              width: totalSize,
              height: totalSize,
              child: CircularProgressIndicator(
                strokeWidth: widget.size > 40 ? 3.5 : 2.5,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.terracotta,
                ),
                backgroundColor: AppColors.turmeric.withValues(alpha: 0.25),
              ),
            ),
          ),

          // Central rotating Kolam Lotus mandala
          RotationTransition(
            turns: Tween<double>(begin: 1.0, end: 0.0).animate(_controller),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: const CustomPaint(
                painter: KolamMandalaPainter(
                  primaryColor: AppColors.terracotta,
                  secondaryColor: AppColors.turmeric,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTraditionalKolamLoader(),
        if (widget.message != null && widget.message!.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBrown,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );

    if (widget.fullScreen) {
      return Scaffold(
        backgroundColor: AppColors.warmCream,
        body: Center(child: content),
      );
    }

    return Center(child: content);
  }
}
