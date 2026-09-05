import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';
import 'torn_paper_chit.dart';

/// Authentic Notebook Paper Canvas with holes, ruled lines, and red margin.
class NotebookPaperPage extends StatelessWidget {
  final Widget child;

  const NotebookPaperPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFE5DFD3,
      ), // Darker desktop desk background
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4EB),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3B000000),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: Offset(2, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    // Notebook Paper Painter
                    Positioned.fill(
                      child: CustomPaint(painter: _NotebookPaperPainter()),
                    ),
                    // Foreground Scrollable Content
                    Positioned.fill(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: 64, // Space to clear holes and red margin line
                          right: 20,
                          top: 24,
                          bottom: 32,
                        ),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotebookPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Off-white paper background
    final bgPaint = Paint()..color = const Color(0xFFF7F4EB);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Horizontal blue ruled lines
    final blueLinePaint = Paint()
      ..color = const Color(0xFFB5CBE3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double lineSpacing = 32.0;
    double y = 48.0;
    while (y < size.height) {
      // Micro-wiggle path for hand-printed paper feel
      final path = Path();
      path.moveTo(0, y);
      path.cubicTo(
        size.width * 0.33,
        y + 0.3,
        size.width * 0.66,
        y - 0.3,
        size.width,
        y,
      );
      canvas.drawPath(path, blueLinePaint);
      y += lineSpacing;
    }

    // 3. Double Vertical Red Margin Line
    const double marginX = 54.0;
    final redMarginPaint = Paint()
      ..color = const Color(0xFFD3483E)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const Offset(marginX, 0),
      Offset(marginX, size.height),
      redMarginPaint,
    );

    canvas.drawLine(
      const Offset(marginX - 3.5, 0),
      Offset(marginX - 3.5, size.height),
      Paint()
        ..color = const Color(0xFFD3483E).withValues(alpha: 0.4)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );

    // 4. Notebook Hole Punches along the left edge
    const double holeX = 26.0;
    const double holeRadius = 8.0;
    const double holeSpacing = 52.0;

    final darkHolePaint = Paint()..color = const Color(0xFF382C26);
    final holeShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 2.5);

    final ringStrokePaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double holeY = 40.0;
    while (holeY < size.height - 20) {
      // Inner dark cutout hole
      canvas.drawCircle(Offset(holeX, holeY), holeRadius, darkHolePaint);
      canvas.drawCircle(Offset(holeX, holeY), holeRadius, holeShadowPaint);

      // Subtle ring highlight edge
      canvas.drawCircle(
        Offset(holeX - 0.5, holeY - 0.5),
        holeRadius,
        ringStrokePaint,
      );

      holeY += holeSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant _NotebookPaperPainter oldDelegate) => false;
}

/// Hand-drawn crown widget in red ink above titles
class HandDrawnCrown extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const HandDrawnCrown({
    super.key,
    this.width = 36,
    this.height = 24,
    this.color = AppColors.redInk,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _CrownPainter(color: color),
    );
  }
}

class _CrownPainter extends CustomPainter {
  final Color color;

  _CrownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Crown Base
    path.moveTo(w * 0.1, h * 0.85);
    path.lineTo(w * 0.9, h * 0.85);

    // Left peak
    path.lineTo(w * 0.85, h * 0.3);
    // Middle dip
    path.lineTo(w * 0.6, h * 0.6);
    // Middle peak
    path.lineTo(w * 0.5, h * 0.15);
    // Left dip
    path.lineTo(w * 0.4, h * 0.6);
    // Leftmost peak
    path.lineTo(w * 0.15, h * 0.3);
    path.close();

    canvas.drawPath(path, paint);

    // Small circles on top of 3 peaks
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.15, h * 0.28), 2.5, fillPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.13), 2.5, fillPaint);
    canvas.drawCircle(Offset(w * 0.85, h * 0.28), 2.5, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _CrownPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Hand-drawn underline widget in red ink
class HandDrawnUnderline extends StatelessWidget {
  final double width;
  final bool isDouble;
  final Color color;

  const HandDrawnUnderline({
    super.key,
    required this.width,
    this.isDouble = false,
    this.color = AppColors.redInk,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, isDouble ? 8 : 4),
      painter: _UnderlinePainter(isDouble: isDouble, color: color),
    );
  }
}

class _UnderlinePainter extends CustomPainter {
  final bool isDouble;
  final Color color;

  _UnderlinePainter({required this.isDouble, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path1 = Path();
    path1.moveTo(2, size.height * 0.3);
    path1.cubicTo(
      size.width * 0.3,
      size.height * 0.3 + 1,
      size.width * 0.7,
      size.height * 0.3 - 1,
      size.width - 2,
      size.height * 0.3 + 0.5,
    );
    canvas.drawPath(path1, paint);

    if (isDouble) {
      final path2 = Path();
      path2.moveTo(4, size.height * 0.85);
      path2.cubicTo(
        size.width * 0.35,
        size.height * 0.85 - 0.5,
        size.width * 0.65,
        size.height * 0.85 + 1,
        size.width - 4,
        size.height * 0.85 - 0.5,
      );
      canvas.drawPath(path2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _UnderlinePainter oldDelegate) =>
      oldDelegate.isDouble != isDouble || oldDelegate.color != color;
}

/// Notebook Hand-Drawn Button with colored pencil hatch shading & accent rays
class HandDrawnButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color pencilFillColor;
  final Color borderColor;
  final Color textColor;
  final bool isLoading;

  const HandDrawnButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.pencilFillColor,
    this.borderColor = AppColors.ballpointBlue,
    this.textColor = AppColors.ballpointBlue,
    this.isLoading = false,
  });

  @override
  State<HandDrawnButton> createState() => _HandDrawnButtonState();
}

class _HandDrawnButtonState extends State<HandDrawnButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null && !widget.isLoading;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 100),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Left hand-drawn accent lines \ | /
                CustomPaint(
                  size: const Size(16, 28),
                  painter: _AccentRaysPainter(
                    isLeft: true,
                    color: widget.borderColor,
                  ),
                ),
                const SizedBox(width: 4),
                // Main Pencil-shaded hand-drawn button box
                CustomPaint(
                  painter: _PencilButtonPainter(
                    pencilFillColor: enabled
                        ? widget.pencilFillColor
                        : Colors.grey.shade300,
                    borderColor: enabled
                        ? widget.borderColor
                        : Colors.grey.shade500,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 140,
                      maxWidth: 260,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    alignment: Alignment.center,
                    child: widget.isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.textColor,
                              ),
                            ),
                          )
                        : Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.kalam(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: enabled
                                  ? widget.textColor
                                  : Colors.grey.shade600,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 4),
                // Right hand-drawn accent lines \ | /
                CustomPaint(
                  size: const Size(16, 28),
                  painter: _AccentRaysPainter(
                    isLeft: false,
                    color: widget.borderColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PencilButtonPainter extends CustomPainter {
  final Color pencilFillColor;
  final Color borderColor;

  _PencilButtonPainter({
    required this.pencilFillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );

    // 1. Soft color fill
    final basePaint = Paint()..color = pencilFillColor.withValues(alpha: 0.85);
    canvas.drawRRect(rect, basePaint);

    // 2. Realistic Pencil Cross-Hatch / Scribble Lines inside button
    canvas.save();
    canvas.clipRRect(rect);

    final hatchPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.18)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Diagonal hatch lines angled at 45 deg
    const double step = 6.0;
    for (double d = -size.height; d < size.width + size.height; d += step) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        hatchPaint,
      );
    }
    canvas.restore();

    // 3. Sketchy hand-drawn double outline in ballpoint blue ink
    final outlinePaint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    const r = 18.0;

    // Organic slightly imperfect rounded rectangle
    path.moveTo(r, 1);
    path.cubicTo(w * 0.5, -1, w * 0.8, 1, w - r, 2);
    path.quadraticBezierTo(w + 1, 2, w - 1, r);
    path.cubicTo(w + 1, h * 0.5, w - 1, h * 0.8, w - 2, h - r);
    path.quadraticBezierTo(w - 2, h + 1, w - r, h - 1);
    path.cubicTo(w * 0.5, h + 2, w * 0.2, h - 1, r, h - 2);
    path.quadraticBezierTo(1, h - 1, 2, h - r);
    path.cubicTo(-1, h * 0.5, 1, h * 0.2, 2, r);
    path.quadraticBezierTo(2, 1, r, 1);

    canvas.drawPath(path, outlinePaint);

    // Second overlapping stroke pass for handwritten ink effect
    final secondPath = Path();
    secondPath.moveTo(r + 4, 3);
    secondPath.lineTo(w - r - 4, 2);
    secondPath.moveTo(w - 3, r + 4);
    secondPath.lineTo(w - 2, h - r - 4);
    secondPath.moveTo(w - r - 4, h - 3);
    secondPath.lineTo(r + 4, h - 2);

    canvas.drawPath(
      secondPath,
      outlinePaint
        ..strokeWidth = 1.0
        ..color = borderColor.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _PencilButtonPainter oldDelegate) =>
      oldDelegate.pencilFillColor != pencilFillColor ||
      oldDelegate.borderColor != borderColor;
}

/// Hand-drawn accent lines radiating from button sides \ | /
class _AccentRaysPainter extends CustomPainter {
  final bool isLeft;
  final Color color;

  _AccentRaysPainter({required this.isLeft, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final cy = size.height / 2;
    if (isLeft) {
      // \ / accent strokes pointing outward left
      canvas.drawLine(Offset(size.width, cy - 8), Offset(2, cy - 14), paint);
      canvas.drawLine(Offset(size.width, cy), Offset(0, cy), paint);
      canvas.drawLine(Offset(size.width, cy + 8), Offset(2, cy + 14), paint);
    } else {
      // / \ accent strokes pointing outward right
      canvas.drawLine(
        Offset(0, cy - 8),
        Offset(size.width - 2, cy - 14),
        paint,
      );
      canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
      canvas.drawLine(
        Offset(0, cy + 8),
        Offset(size.width - 2, cy + 14),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AccentRaysPainter oldDelegate) =>
      oldDelegate.isLeft != isLeft || oldDelegate.color != color;
}

/// Hand-drawn sketchy input field container
class HandDrawnTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final Color? fillColor;
  final Color? borderColor;

  const HandDrawnTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.style,
    this.hintStyle,
    this.fillColor,
    this.borderColor,
  });

  @override
  State<HandDrawnTextField> createState() => _HandDrawnTextFieldState();
}

class _HandDrawnTextFieldState extends State<HandDrawnTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SketchyBoxPainter(
        isFocused: _isFocused,
        fillColor: widget.fillColor ?? const Color(0xFFFFFDF5),
        borderColor: widget.borderColor ??
            (_isFocused ? AppColors.redInk : AppColors.ballpointBlue),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          maxLength: widget.maxLength,
          textCapitalization: widget.textCapitalization,
          textAlign: widget.textAlign,
          onChanged: widget.onChanged,
          style:
              widget.style ??
              GoogleFonts.patrickHand(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.ballpointBlue,
              ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle:
                widget.hintStyle ??
                GoogleFonts.caveat(
                  fontSize: 17,
                  color: AppColors.ballpointBlue.withValues(alpha: 0.45),
                ),
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }
}

class _SketchyBoxPainter extends CustomPainter {
  final bool isFocused;
  final Color fillColor;
  final Color borderColor;

  _SketchyBoxPainter({
    this.isFocused = false,
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const r = 16.0;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(r),
    );

    // 1. Soft paper background color fill
    final bgPaint = Paint()..color = fillColor;
    canvas.drawRRect(rect, bgPaint);

    // 2. Realistic Pencil Cross-Hatch / Scribble Lines inside input box
    canvas.save();
    canvas.clipRRect(rect);
    final hatchPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double step = 6.0;
    for (double d = -h; d < w + h; d += step) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + h, h),
        hatchPaint,
      );
    }
    canvas.restore();

    // 3. Primary Organic Hand-Drawn Handwritten Pen Stroke
    final mainPenPaint = Paint()
      ..color = borderColor
      ..strokeWidth = isFocused ? 2.4 : 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(r, 1);
    path.cubicTo(w * 0.5, -1, w * 0.8, 1, w - r, 2);
    path.quadraticBezierTo(w + 1, 2, w - 1, r);
    path.cubicTo(w + 1, h * 0.5, w - 1, h * 0.8, w - 2, h - r);
    path.quadraticBezierTo(w - 2, h + 1, w - r, h - 1);
    path.cubicTo(w * 0.5, h + 2, w * 0.2, h - 1, r, h - 2);
    path.quadraticBezierTo(1, h - 1, 2, h - r);
    path.cubicTo(-1, h * 0.5, 1, h * 0.2, 2, r);
    path.quadraticBezierTo(2, 1, r, 1);

    canvas.drawPath(path, mainPenPaint);

    // 4. Secondary Sketchy Overlapping Ink Pass for Handwritten Pen Effect
    final secondPath = Path();
    secondPath.moveTo(r + 4, 3);
    secondPath.lineTo(w - r - 4, 2);
    secondPath.moveTo(w - 3, r + 4);
    secondPath.lineTo(w - 2, h - r - 4);
    secondPath.moveTo(w - r - 4, h - 3);
    secondPath.lineTo(r + 4, h - 2);
    secondPath.moveTo(3, h - r - 4);
    secondPath.lineTo(2, r + 4);

    canvas.drawPath(
      secondPath,
      mainPenPaint
        ..strokeWidth = isFocused ? 1.4 : 1.0
        ..color = borderColor.withValues(alpha: 0.65),
    );
  }

  @override
  bool shouldRepaint(covariant _SketchyBoxPainter oldDelegate) =>
      oldDelegate.isFocused != isFocused ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.borderColor != borderColor;
}

/// Notebook Header Bar: Crown + RAJA RANI + Badges ([DEV ON], [ROUND 1/1]) + Action Button
class NotebookHeader extends StatelessWidget {
  final int currentRound;
  final int totalRounds;
  final bool isDevMode;
  final VoidCallback? onScoreboardTap;
  final VoidCallback? onDevToggle;

  const NotebookHeader({
    super.key,
    this.currentRound = 1,
    this.totalRounds = 1,
    this.isDevMode = true,
    this.onScoreboardTap,
    this.onDevToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Crown + RAJA RANI Title
          Row(
            children: [
              const HandDrawnCrown(width: 24, height: 18),
              const SizedBox(width: 6),
              Text(
                'RAJA RANI',
                style: GoogleFonts.kalam(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ballpointBlue,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                ' \'',
                style: GoogleFonts.kalam(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ballpointBlue,
                ),
              ),
            ],
          ),

          // Center/Right: Badges & Actions
          Row(
            children: [
              if (onDevToggle != null) ...[
                GestureDetector(
                  onTap: onDevToggle,
                  child: NotebookBadge(
                    label: isDevMode ? 'DEV ON' : 'DEV OFF',
                    color: isDevMode ? AppColors.redInk : AppColors.pencilGrey,
                    icon: isDevMode
                        ? Icons.bug_report
                        : Icons.bug_report_outlined,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              NotebookBadge(
                label: 'ROUND $currentRound / $totalRounds',
                color: AppColors.ballpointBlue,
              ),
              if (onScoreboardTap != null) ...[
                const SizedBox(width: 8),
                NotebookScoreButton(onPressed: onScoreboardTap),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Sketchy hand-drawn rectangular badge ([DEV ON], [ROUND 1 / 1])
class NotebookBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const NotebookBadge({
    super.key,
    required this.label,
    this.color = AppColors.ballpointBlue,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BadgeBorderPainter(color: color),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.kalam(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeBorderPainter extends CustomPainter {
  final Color color;

  _BadgeBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(4, 1);
    path.lineTo(w - 4, 2);
    path.quadraticBezierTo(w, 2, w - 1, 5);
    path.lineTo(w - 2, h - 4);
    path.quadraticBezierTo(w - 2, h, w - 5, h - 1);
    path.lineTo(4, h - 2);
    path.quadraticBezierTo(1, h - 2, 2, h - 5);
    path.lineTo(1, 4);
    path.quadraticBezierTo(1, 1, 4, 1);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BadgeBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Circular hand-drawn Scoreboard action button
class NotebookScoreButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const NotebookScoreButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: CustomPaint(
        painter: _ScoreButtonPainter(),
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.more_vert, size: 18, color: AppColors.ballpointBlue),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreButtonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ballpointBlue
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 1,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreButtonPainter oldDelegate) => false;
}

/// Result Box (e.g. ★ GOOD GAME! Here is the final score card:)
class NotebookResultCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const NotebookResultCard({
    super.key,
    this.title = '★ GOOD GAME!',
    this.subtitle = 'Here is the final score card:',
    this.icon = Icons.star,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PencilBoxPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '\\ \\ ',
                    style: GoogleFonts.kalam(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ballpointBlue.withValues(alpha: 0.6),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.ballpointBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title.replaceAll('★ ', ''),
                    style: GoogleFonts.kalam(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ballpointBlue,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    ' / /',
                    style: GoogleFonts.kalam(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ballpointBlue.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.caveat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.ballpointBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PencilBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );

    // Soft background tint
    final bgPaint = Paint()..color = const Color(0xFFF2F6FA);
    canvas.drawRRect(rect, bgPaint);

    // Pencil cross-hatch shading inside
    canvas.save();
    canvas.clipRRect(rect);
    final hatchPaint = Paint()
      ..color = AppColors.ballpointBlue.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;
    for (double d = -size.height; d < size.width + size.height; d += 6) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        hatchPaint,
      );
    }
    canvas.restore();

    // Sketchy double-line outline in ballpoint blue ink
    final outlinePaint = Paint()
      ..color = AppColors.ballpointBlue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(rect, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _PencilBoxPainter oldDelegate) => false;
}

/// Notebook Score Table Widget matching Reference Image #2 exactly!
class NotebookScoreTable extends StatelessWidget {
  final List<Map<String, dynamic>> playerScores;
  final bool isFinalScore;

  const NotebookScoreTable({
    super.key,
    required this.playerScores,
    this.isFinalScore = true,
  });

  @override
  Widget build(BuildContext context) {
    // Collect all round numbers from all player data entries
    final Set<int> allRounds = {};
    for (final p in playerScores) {
      if (p['roundScores'] is Map<int, int>) {
        final Map<int, int> rMap = p['roundScores'] as Map<int, int>;
        allRounds.addAll(rMap.keys);
      }
    }

    final List<int> sortedRoundNumbers = allRounds.isEmpty
        ? [1]
        : (allRounds.toList()..sort());

    return CustomPaint(
      painter: _PencilBoxPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table Header: FINAL SCORE SHEET ... TOTAL SCORE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFinalScore ? 'FINAL SCORE SHEET' : 'SCORE BOARD',
                      style: GoogleFonts.kalam(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ballpointBlue,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const HandDrawnUnderline(width: 140, isDouble: false),
                  ],
                ),
                Text(
                  'TOTAL SCORE',
                  style: GoogleFonts.kalam(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.redInk,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Table Column Headers: Rank | Player Name | R1 | R2 ... | TOTAL
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.blueRuling, width: 1.2),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      'Rank',
                      style: GoogleFonts.kalam(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ballpointBlue,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Player Name',
                      style: GoogleFonts.kalam(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ballpointBlue,
                      ),
                    ),
                  ),
                  ...sortedRoundNumbers.map((rNum) {
                    return Expanded(
                      flex: 2,
                      child: Text(
                        'R$rNum',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.kalam(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ballpointBlue,
                        ),
                      ),
                    );
                  }),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'TOTAL',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.kalam(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.penGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Table Body Rows
            Column(
              children: List.generate(playerScores.length, (index) {
                final item = playerScores[index];
                final String name = item['name'] ?? 'Player';
                final Map<int, int> roundScoresMap =
                    (item['roundScores'] is Map<int, int>)
                    ? item['roundScores'] as Map<int, int>
                    : {};
                final int legacyRoundPts = item['roundPoints'] ?? 0;
                final int totalPts = item['totalPoints'] ?? 0;
                final int rank = index + 1;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.blueRuling,
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Circled Rank Number (1) in red, (2), (3)...
                      SizedBox(
                        width: 36,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: rank == 1
                                    ? AppColors.redInk
                                    : AppColors.ballpointBlue,
                                width: 1.4,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$rank',
                              style: GoogleFonts.kalam(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: rank == 1
                                    ? AppColors.redInk
                                    : AppColors.ballpointBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Player Name
                      Expanded(
                        flex: 3,
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.patrickHand(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ballpointBlue,
                          ),
                        ),
                      ),
                      // Dynamic Round Score Cells (+5000) for R1, R2, R3...
                      ...sortedRoundNumbers.map((rNum) {
                        final rPts = roundScoresMap.containsKey(rNum)
                            ? roundScoresMap[rNum]!
                            : (rNum == 1 ? legacyRoundPts : 0);
                        return Expanded(
                          flex: 2,
                          child: Text(
                            '+$rPts',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.patrickHand(
                              fontSize: 14,
                              color: AppColors.pencilGrey,
                            ),
                          ),
                        );
                      }),
                      // Total Score
                      Expanded(
                        flex: 2,
                        child: Text(
                          '$totalPts',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.kalam(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ballpointBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Unfolding Secret Role Reveal Dialog
class SecretRoleRevealDialog extends StatefulWidget {
  final String playerName;
  final String role;
  final int points;

  const SecretRoleRevealDialog({
    super.key,
    required this.playerName,
    required this.role,
    required this.points,
  });

  @override
  State<SecretRoleRevealDialog> createState() => _SecretRoleRevealDialogState();
}

class _SecretRoleRevealDialogState extends State<SecretRoleRevealDialog> {
  bool _isFolded = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isFolded = false;
        });
      }
    });
  }

  void _foldAndClose() {
    setState(() {
      _isFolded = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF7F4EB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.ballpointBlue, width: 2),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'UNFOLDING PAPER CHIT...',
              style: GoogleFonts.kalam(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.ballpointBlue,
              ),
            ),
            const SizedBox(height: 16),

            TornPaperChit(
              label: 'YOUR ROLE',
              role: widget.role,
              points: widget.points,
              isFolded: _isFolded,
              isSelected: true,
              width: 140,
              height: 165,
              onTap: _foldAndClose,
            ),

            const SizedBox(height: 20),
            Text(
              'KEEP IT SECRET!',
              style: GoogleFonts.kalam(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.redInk,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Do not let other players see your screen.',
              textAlign: TextAlign.center,
              style: GoogleFonts.caveat(
                fontSize: 16,
                color: AppColors.pencilGrey,
              ),
            ),
            const SizedBox(height: 20),

            HandDrawnButton(
              label: 'GOT IT! KEEP SECRET',
              pencilFillColor: AppColors.pencilBlueFill,
              onPressed: _foldAndClose,
            ),
          ],
        ),
      ),
    );
  }
}

/// Guess Result Dialog showing correct/wrong guess, revealed role, and wait message
class GuessResultDialog extends StatelessWidget {
  final bool isCorrect;
  final String guesserName;
  final String targetName;
  final String targetRole;
  final String message;
  final VoidCallback onClose;

  const GuessResultDialog({
    super.key,
    required this.isCorrect,
    required this.guesserName,
    required this.targetName,
    required this.targetRole,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF7F4EB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isCorrect ? AppColors.penGreen : AppColors.redInk,
          width: 2.2,
        ),
      ),
      contentPadding: const EdgeInsets.all(16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.stars_rounded : Icons.cancel_outlined,
            size: 48,
            color: isCorrect ? AppColors.penGreen : AppColors.redInk,
          ),
          const SizedBox(height: 8),
          Text(
            isCorrect ? 'YOUR GUESS IS CORRECT!' : 'WRONG GUESS!',
            textAlign: TextAlign.center,
            style: GoogleFonts.kalam(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isCorrect ? AppColors.penGreen : AppColors.redInk,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          HandDrawnUnderline(
            width: 180,
            isDouble: true,
            color: isCorrect ? AppColors.penGreen : AppColors.redInk,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCorrect
                  ? AppColors.pencilGreenFill.withValues(alpha: 0.3)
                  : AppColors.pencilYellowFill.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCorrect ? AppColors.penGreen : AppColors.ballpointBlue,
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  isCorrect
                      ? '✨ $targetName IS THE $targetRole! ✨'
                      : '❌ $targetName IS NOT THE $targetRole',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.patrickHand(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ballpointBlue,
                  ),
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.caveat(
                      fontSize: 17,
                      color: AppColors.pencilGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.blueRuling, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  size: 16,
                  color: AppColors.redInk,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Please wait for other players to make their guess!',
                    style: GoogleFonts.kalam(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.redInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          HandDrawnButton(
            label: 'OK, WAIT FOR OTHERS',
            pencilFillColor: isCorrect
                ? AppColors.pencilGreenFill
                : AppColors.pencilBlueFill,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
