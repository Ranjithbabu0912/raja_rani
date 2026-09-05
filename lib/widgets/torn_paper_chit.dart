import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Realistic Double-Folded Notebook Paper Role Chit.
///
/// Animation Sequence:
/// 1. Compact Rectangular Folded Chit (1/2 width x 1/2 height).
/// 2. Step 1 (Top Half Unfold): Bottom half stays fixed. Top flap rotates X-axis
///    top-to-bottom / upward around horizontal crease hinge (y = height / 2).
/// 3. Step 2 (Left Half Unfold): Stationary anchor stays in exact position. Left flap
///    rotates Y-axis left-to-right / leftward around vertical crease hinge (x = width / 2).
/// 4. Fully Flat Paper Sheet without fold marks.
/// 5. Secret Role Text Revealed in center.
class TornPaperChit extends StatefulWidget {
  final String label;
  final String? role; // e.g. "RAJA", "RANI", etc.
  final int? points; // e.g. 5000
  final bool isFolded;
  final bool isSelected;
  final bool isTaken;
  final String? takenByPlayerName;
  final double angle; // Physical tilt angle in radians
  final VoidCallback? onTap;
  final double width;
  final double height;

  const TornPaperChit({
    super.key,
    this.label = '',
    this.role,
    this.points,
    this.isFolded = true,
    this.isSelected = false,
    this.isTaken = false,
    this.takenByPlayerName,
    this.angle = 0.0,
    this.onTap,
    this.width = 120,
    this.height = 160,
  });

  @override
  State<TornPaperChit> createState() => _TornPaperChitState();
}

class _TornPaperChitState extends State<TornPaperChit>
    with SingleTickerProviderStateMixin {
  late AnimationController _unfoldController;
  late Animation<double> _step1TopUnfold;
  late Animation<double> _step2SideUnfold;
  late Animation<double> _roleFadeIn;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _unfoldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Step 1: Top half unfolds upward around horizontal crease (0.0 -> 0.45)
    _step1TopUnfold = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _unfoldController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    // Step 2: Left half unfolds sideways around vertical crease (0.50 -> 0.85)
    _step2SideUnfold = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _unfoldController,
        curve: const Interval(0.50, 0.85, curve: Curves.easeInOutCubic),
      ),
    );

    // Step 3: Handwritten role text fades in after paper is flat (0.85 -> 1.0)
    _roleFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _unfoldController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeIn),
      ),
    );

    if (!widget.isFolded) {
      _unfoldController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TornPaperChit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFolded != oldWidget.isFolded) {
      if (widget.isFolded) {
        _unfoldController.reverse();
      } else {
        _unfoldController.forward();
      }
    }
  }

  @override
  void dispose() {
    _unfoldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: widget.angle,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isHovered = true),
          onTapCancel: () => setState(() => _isHovered = false),
          onTapUp: (_) => setState(() => _isHovered = false),
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _unfoldController,
            builder: (context, child) {
              final step1Val = _step1TopUnfold.value;
              final step2Val = _step2SideUnfold.value;
              final roleOpacity = _roleFadeIn.value;
              final totalProgress = _unfoldController.value;

              // Physical hover / touch lift offset
              final double liftOffsetY = _isHovered ? -6.0 : 0.0;
              final double shadowBlur = _isHovered ? 12.0 : 5.0;

              return Transform.translate(
                offset: Offset(0, liftOffsetY),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Closed Compact Folded Chit (Rectangle)
                    if (totalProgress < 0.05)
                      _buildCompactFoldedChit(context, shadowBlur),

                    // Continuous 2-Stage Hinge Unfold System (No position jumps)
                    if (totalProgress >= 0.05)
                      _buildHingePanelUnfold(
                        context,
                        step1Val,
                        step2Val,
                        roleOpacity,
                        shadowBlur,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Compact Folded Rectangular Chit (1/2 width x 1/2 height)
  Widget _buildCompactFoldedChit(BuildContext context, double shadowBlur) {
    final double qw = widget.width * 0.5;
    final double qh = widget.height * 0.5;

    return Container(
      width: qw,
      height: qh,
      decoration: BoxDecoration(
        boxShadow: [
          // Primary soft paper drop shadow
          BoxShadow(
            color: Colors.black.withValues(
              alpha: widget.isSelected ? 0.28 : (_isHovered ? 0.22 : 0.15),
            ),
            blurRadius: shadowBlur + 2,
            spreadRadius: widget.isSelected ? 1.5 : 0,
            offset: Offset(3, _isHovered ? 7 : 4),
          ),
          // Secondary subtle contact shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _FoldedQuadChitPainter(
          isSelected: widget.isSelected,
          isTaken: widget.isTaken,
        ),
        child: Center(
          child: widget.isTaken
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.penGreen,
                        size: 18,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.takenByPlayerName ?? 'TAKEN ✓',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.handwrittenBody(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.inkBlack,
                        ),
                      ),
                    ],
                  ),
                )
              : null, // Cross mark removed — shadow only
        ),
      ),
    );
  }

  /// Panel Hinge Unfold System (Step 1 top flap, Step 2 side flap, Stationary anchors)
  Widget _buildHingePanelUnfold(
    BuildContext context,
    double step1Val,
    double step2Val,
    double roleOpacity,
    double shadowBlur,
  ) {
    final double w = widget.width;
    final double h = widget.height;
    final double qw = w / 2;
    final double qh = h / 2;
    final Color roleColor = _getRoleColor(widget.role ?? '');

    // Angle calculations for hinges:
    // Step 1: Top half rotates X-axis 180° -> 0° around horizontal crease (y = qh)
    final double topAngleX = (1.0 - step1Val) * math.pi;

    // Step 2: Left half rotates Y-axis 180° -> 0° around vertical crease (x = qw)
    final double sideAngleY = (1.0 - step2Val) * math.pi;

    // Translation offsets to keep paper centered throughout 2-step unfolding:
    final double shiftX = -qw / 2 * (1.0 - step2Val);
    final double shiftY = -qh / 2 * (1.0 - step1Val);

    return Transform.translate(
      offset: Offset(shiftX, shiftY),
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15 + (step2Val * 0.10)),
              blurRadius: shadowBlur + (step1Val * 3),
              offset: Offset(2, 3 + (step1Val * 2)),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // -----------------------------------------------------------------
            // LAYER 1: Bottom-Right Quadrant (BR) — Base Anchor (Fixed)
            // -----------------------------------------------------------------
            Positioned(
              left: qw,
              top: qh,
              width: qw,
              height: qh,
              child: CustomPaint(
                painter: _NotebookPaperQuadrantPainter(
                  quadrant: _Quadrant.bottomRight,
                  borderColor: Colors.transparent,
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // LAYER 2: Top-Right Quadrant (TR) — Step 1 Vertical Unfold Hinge
            // -----------------------------------------------------------------
            Positioned(
              left: qw,
              top: 0,
              width: qw,
              height: qh,
              child: Transform(
                alignment:
                    Alignment.bottomCenter, // Crease hinge line at y = qh
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0018)
                  ..rotateX(topAngleX),
                child: CustomPaint(
                  painter: _NotebookPaperQuadrantPainter(
                    quadrant: _Quadrant.topRight,
                    borderColor: Colors.transparent,
                    shadowOpacity: (1.0 - step1Val) * 0.25,
                    isFlipped: topAngleX > (math.pi / 2),
                  ),
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // LAYER 3: Left Half Flap (TL + BL) — Step 2 Horizontal Unfold Hinge
            // -----------------------------------------------------------------
            Positioned(
              left: 0,
              top: 0,
              width: qw,
              height: h,
              child: Transform(
                alignment: Alignment.centerRight, // Crease hinge line at x = qw
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0018)
                  ..rotateY(sideAngleY),
                child: Stack(
                  children: [
                    // Bottom-Left Quadrant (BL) inside Left Half
                    Positioned(
                      left: 0,
                      top: qh,
                      width: qw,
                      height: qh,
                      child: CustomPaint(
                        painter: _NotebookPaperQuadrantPainter(
                          quadrant: _Quadrant.bottomLeft,
                          borderColor: Colors.transparent,
                          shadowOpacity: (1.0 - step2Val) * 0.25,
                          isFlipped: sideAngleY > (math.pi / 2),
                        ),
                      ),
                    ),

                    // Top-Left Quadrant (TL) inside Left Half (Unfolds X-axis with TR during Step 1)
                    Positioned(
                      left: 0,
                      top: 0,
                      width: qw,
                      height: qh,
                      child: Transform(
                        alignment: Alignment.bottomCenter,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0018)
                          ..rotateX(topAngleX),
                        child: CustomPaint(
                          painter: _NotebookPaperQuadrantPainter(
                            quadrant: _Quadrant.topLeft,
                            borderColor: Colors.transparent,
                            shadowOpacity: (1.0 - step1Val) * 0.25,
                            isFlipped:
                                topAngleX > (math.pi / 2) ||
                                sideAngleY > (math.pi / 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // LAYER 4: Secret Role Reveal Text (Fades in when flat)
            // -----------------------------------------------------------------
            if (roleOpacity > 0.05)
              Opacity(
                opacity: roleOpacity,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          (widget.role ?? 'ROLE').toUpperCase(),
                          textAlign: TextAlign.center,
                          style: AppTypography.handwrittenTitle(
                            fontSize: 22,
                            color: roleColor,
                            letterSpacing: 2.0,
                          ),
                        ),
                        if (widget.points != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${widget.points} PTS',
                            style: AppTypography.handwrittenTitle(
                              fontSize: 18,
                              color: roleColor,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          _getRoleHint(widget.role ?? ''),
                          textAlign: TextAlign.center,
                          style: AppTypography.handwrittenSubtle(
                            fontSize: 12,
                            color: AppColors.inkBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'raja':
        return AppColors.roleRaja;
      case 'rani':
        return AppColors.roleRani;
      case 'manthiri':
        return AppColors.roleManthiri;
      case 'sippai':
        return AppColors.roleSippai;
      case 'police':
        return AppColors.rolePolice;
      case 'thirudan':
        return AppColors.roleThirudan;
      default:
        return AppColors.ballpointBlue;
    }
  }

  String _getRoleHint(String role) {
    switch (role.toLowerCase()) {
      case 'raja':
        return 'Find the Rani!';
      case 'rani':
        return 'Keep role secret';
      case 'manthiri':
        return 'Advisor to Raja';
      case 'sippai':
        return 'Order to the Police';
      case 'police':
        return 'Catch Thirudan';
      case 'thirudan':
        return 'Hide from Police';
      default:
        return 'Keep secret';
    }
  }
}

enum _Quadrant { topLeft, topRight, bottomLeft, bottomRight }

/// Custom painter for individual paper sheet quadrants (clean notebook ruling, red margin, no fold marks).
class _NotebookPaperQuadrantPainter extends CustomPainter {
  final _Quadrant quadrant;
  final Color borderColor;
  final double shadowOpacity;
  final bool isFlipped;

  _NotebookPaperQuadrantPainter({
    required this.quadrant,
    required this.borderColor,
    this.shadowOpacity = 0.0,
    this.isFlipped = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Generate realistic torn paper quadrant path
    final Path paperPath = _buildTornQuadrantPath(w, h);

    // Paper Fill
    final paperPaint = Paint()
      ..color = const Color(0xFFFFFDF8)
      ..style = PaintingStyle.fill;
    canvas.drawPath(paperPath, paperPaint);

    canvas.save();
    canvas.clipPath(paperPath);

    if (isFlipped) {
      // Flipped Back Face of Paper
      final backStroke = Paint()
        ..color = AppColors.blueRuling.withValues(alpha: 0.25)
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke;
      for (double y = 14; y < h - 4; y += 18) {
        canvas.drawLine(Offset(2, y), Offset(w - 2, y), backStroke);
      }
    } else {
      // Front Face of Paper: Blue ruling lines
      final bluePaint = Paint()
        ..color = AppColors.blueRuling.withValues(alpha: 0.65)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;

      for (double y = 14; y < h - 4; y += 18) {
        canvas.drawLine(Offset(2, y), Offset(w - 4, y), bluePaint);
      }

      // Red margin line (only on left-side quadrants at local x = 16)
      if (quadrant == _Quadrant.topLeft || quadrant == _Quadrant.bottomLeft) {
        final redPaint = Paint()
          ..color = AppColors.redMargin.withValues(alpha: 0.6)
          ..strokeWidth = 0.9
          ..style = PaintingStyle.stroke;
        canvas.drawLine(const Offset(16, 0), Offset(16, h), redPaint);
      }
    }

    canvas.restore();

    // Dynamic Hinge Shadow
    if (shadowOpacity > 0.01) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: shadowOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawPath(paperPath, shadowPaint);
    }

    // Outer Paper Torn Border Stroke ONLY (No interior fold mark lines!)
    final Color strokeColor = (borderColor != Colors.transparent)
        ? borderColor.withValues(alpha: 0.65)
        : AppColors.blueRuling.withValues(alpha: 0.45);

    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final Path strokePath = _buildOuterTornStrokePath(w, h);
    canvas.drawPath(strokePath, strokePaint);
  }

  /// Builds torn paper path for individual quadrant (jagged outer edges, flat inner fold creases).
  Path _buildTornQuadrantPath(double w, double h) {
    final Path path = Path();

    switch (quadrant) {
      case _Quadrant.topLeft:
        path.moveTo(0, 0);
        for (double x = 0; x < w; x += 6) {
          final dy = (x % 12 == 0) ? -1.4 : 0.8;
          path.lineTo(x + 3, dy);
        }
        path.lineTo(w, 0);
        path.lineTo(w, h);
        path.lineTo(0, h);
        for (double y = h; y > 0; y -= 6) {
          final dx = (y % 12 == 0) ? -1.4 : 0.8;
          path.lineTo(dx, y - 3);
        }
        path.close();
        break;

      case _Quadrant.topRight:
        path.moveTo(0, 0);
        for (double x = 0; x < w; x += 6) {
          final dy = (x % 12 == 0) ? -1.4 : 0.8;
          path.lineTo(x + 3, dy);
        }
        path.lineTo(w, 0);
        for (double y = 0; y < h; y += 6) {
          final dx = w + ((y % 12 == 0) ? 1.4 : -0.8);
          path.lineTo(dx, y + 3);
        }
        path.lineTo(w, h);
        path.lineTo(0, h);
        path.lineTo(0, 0);
        path.close();
        break;

      case _Quadrant.bottomLeft:
        path.moveTo(0, 0);
        path.lineTo(w, 0);
        path.lineTo(w, h);
        for (double x = w; x > 0; x -= 6) {
          final dy = h + ((x % 12 == 0) ? 1.4 : -0.8);
          path.lineTo(x - 3, dy);
        }
        path.lineTo(0, h);
        for (double y = h; y > 0; y -= 6) {
          final dx = (y % 12 == 0) ? -1.4 : 0.8;
          path.lineTo(dx, y - 3);
        }
        path.close();
        break;

      case _Quadrant.bottomRight:
        path.moveTo(0, 0);
        path.lineTo(w, 0);
        for (double y = 0; y < h; y += 6) {
          final dx = w + ((y % 12 == 0) ? 1.4 : -0.8);
          path.lineTo(dx, y + 3);
        }
        path.lineTo(w, h);
        for (double x = w; x > 0; x -= 6) {
          final dy = h + ((x % 12 == 0) ? 1.4 : -0.8);
          path.lineTo(x - 3, dy);
        }
        path.lineTo(0, h);
        path.lineTo(0, 0);
        path.close();
        break;
    }

    return path;
  }

  /// Builds stroke path ONLY along outer torn paper edges (skips interior fold creases).
  Path _buildOuterTornStrokePath(double w, double h) {
    final Path path = Path();

    switch (quadrant) {
      case _Quadrant.topLeft:
        path.moveTo(0, 0);
        for (double x = 0; x < w; x += 6) {
          final dy = (x % 12 == 0) ? -1.4 : 0.8;
          path.lineTo(x + 3, dy);
        }
        path.lineTo(w, 0);

        path.moveTo(0, h);
        for (double y = h; y > 0; y -= 6) {
          final dx = (y % 12 == 0) ? -1.4 : 0.8;
          path.lineTo(dx, y - 3);
        }
        path.lineTo(0, 0);
        break;

      case _Quadrant.topRight:
        path.moveTo(0, 0);
        for (double x = 0; x < w; x += 6) {
          final dy = (x % 12 == 0) ? -1.4 : 0.8;
          path.lineTo(x + 3, dy);
        }
        path.lineTo(w, 0);
        for (double y = 0; y < h; y += 6) {
          final dx = w + ((y % 12 == 0) ? 1.4 : -0.8);
          path.lineTo(dx, y + 3);
        }
        path.lineTo(w, h);
        break;

      case _Quadrant.bottomLeft:
        path.moveTo(w, h);
        for (double x = w; x > 0; x -= 6) {
          final dy = h + ((x % 12 == 0) ? 1.4 : -0.8);
          path.lineTo(x - 3, dy);
        }
        path.lineTo(0, h);
        for (double y = h; y > 0; y -= 6) {
          final dx = (y % 12 == 0) ? -1.4 : 0.8;
          path.lineTo(dx, y - 3);
        }
        path.lineTo(0, 0);
        break;

      case _Quadrant.bottomRight:
        path.moveTo(w, 0);
        for (double y = 0; y < h; y += 6) {
          final dx = w + ((y % 12 == 0) ? 1.4 : -0.8);
          path.lineTo(dx, y + 3);
        }
        path.lineTo(w, h);
        for (double x = w; x > 0; x -= 6) {
          final dy = h + ((x % 12 == 0) ? 1.4 : -0.8);
          path.lineTo(x - 3, dy);
        }
        path.lineTo(0, h);
        break;
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _NotebookPaperQuadrantPainter oldDelegate) {
    return oldDelegate.quadrant != quadrant ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.shadowOpacity != shadowOpacity ||
        oldDelegate.isFlipped != isFlipped;
  }
}

/// Painter for Folded Rectangular Quad-Chit (1/2 width x 1/2 height).
class _FoldedQuadChitPainter extends CustomPainter {
  final bool isSelected;
  final bool isTaken;

  _FoldedQuadChitPainter({required this.isSelected, required this.isTaken});

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;

    // Irregular torn edges around folded paper rectangle
    path.moveTo(0, 0);
    for (double x = 0; x < w; x += 8) {
      final dy = (x % 16 == 0) ? -1.0 : 0.8;
      path.lineTo(x + 4, dy);
    }
    path.lineTo(w, 0);

    for (double y = 0; y < h; y += 8) {
      final dx = (y % 16 == 0) ? w + 1.0 : w - 0.8;
      path.lineTo(dx, y + 4);
    }
    path.lineTo(w, h);

    path.lineTo(0, h);

    for (double y = h; y > 0; y -= 8) {
      final dx = (y % 16 == 0) ? -1.0 : 0.8;
      path.lineTo(dx, y - 4);
    }
    path.close();

    // Fill paper body
    final paperPaint = Paint()
      ..color = isSelected
          ? const Color(0xFFFFFDF5)
          : isTaken
          ? const Color(0xFFF0EAE0)
          : AppColors.paperWhite
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paperPaint);

    // Blue ruling lines
    final bluePaint = Paint()
      ..color = AppColors.blueRuling.withValues(alpha: 0.6)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (double y = 14; y < h - 6; y += 16) {
      canvas.drawLine(Offset(4, y), Offset(w - 4, y), bluePaint);
    }

    // Red margin line
    final redPaint = Paint()
      ..color = AppColors.redMargin.withValues(alpha: 0.5)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(14, 2), Offset(14, h - 2), redPaint);

    // Outer pen border stroke
    final strokePaint = Paint()
      ..color = isSelected
          ? AppColors.ballpointBlue
          : isTaken
          ? AppColors.pencilGrey
          : AppColors.blueRuling
      ..strokeWidth = isSelected ? 1.8 : 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _FoldedQuadChitPainter oldDelegate) {
    return oldDelegate.isSelected != isSelected ||
        oldDelegate.isTaken != isTaken;
  }
}
