import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/kolam_painter.dart';
import 'lobby_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeInAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
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
        pageBuilder: (context, animation, secondaryAnimation) => const LobbyScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
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
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: GestureDetector(
        onTap: _navigateToLobby,
        child: CustomPaint(
          size: Size.infinite,
          painter: const KolamCornerPainter(color: AppColors.terracotta, strokeWidth: 2.0),
          child: Center(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Traditional Invitation Frame Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                        decoration: BoxDecoration(
                          color: AppColors.cardCream,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.terracotta, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x293B2418),
                              blurRadius: 16,
                              spreadRadius: 2,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Kolam Mandala emblem
                            const SizedBox(
                              width: 80,
                              height: 80,
                              child: CustomPaint(
                                painter: KolamMandalaPainter(
                                  primaryColor: AppColors.terracotta,
                                  secondaryColor: AppColors.turmeric,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'RAJA RANI',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: AppColors.darkBrown,
                                letterSpacing: 2.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 2,
                              width: 100,
                              color: AppColors.terracotta,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Traditional Family Game',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.leafGreen,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'தமிழ் பாரம்பரிய விளையாட்டு',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.darkBrown,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app, color: AppColors.terracotta, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Tap anywhere to start',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.darkBrown,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
