import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';
import '../widgets/handdrawn_components.dart';
import 'lobby_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _penAnimation;
  late final Animation<double> _subtitleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _penAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _subtitleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Auto navigate after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _navigateToLobby();
      }
    });
  }

  void _navigateToLobby() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LobbyScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotebookPaperPage(
      child: GestureDetector(
        onTap: _navigateToLobby,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Crown Doodles
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HandDrawnCrown(width: 34, height: 24),
                      SizedBox(width: 48),
                      HandDrawnCrown(width: 34, height: 24),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Animated Handwritten Title: RAJA RANI
                  Opacity(
                    opacity: _penAnimation.value,
                    child: Transform.scale(
                      scale: 0.9 + (_penAnimation.value * 0.1),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '\\ \\ ',
                                style: GoogleFonts.kalam(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ballpointBlue
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              Text(
                                'RAJA RANI',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.kalam(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ballpointBlue,
                                  letterSpacing: 3.5,
                                ),
                              ),
                              Text(
                                ' / /',
                                style: GoogleFonts.kalam(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ballpointBlue
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Hand-drawn double red underline
                          HandDrawnUnderline(
                            width: 180 * _penAnimation.value,
                            isDouble: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Subtitle writing: "KANDUPUDI?"
                  Opacity(
                    opacity: _subtitleAnimation.value,
                    child: Column(
                      children: [
                        Text(
                          '"KANDUPUDI?"',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.kalam(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ballpointBlue,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Traditional Paper Role Game',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.caveat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pencilGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 64),

                  // Tap prompt note
                  Opacity(
                    opacity: _subtitleAnimation.value,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.touch_app,
                          color: AppColors.penGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tap notebook sheet to start game...',
                          style: GoogleFonts.caveat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.penGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
