import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';
import '../widgets/handdrawn_components.dart';
import '../widgets/torn_paper_chit.dart';
import 'game_screen.dart';

class RoleScreen extends StatelessWidget {
  final String roomId;
  final String role;
  final int points;

  const RoleScreen({
    super.key,
    required this.roomId,
    required this.role,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return NotebookPaperPage(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'YOUR SECRET ROLE',
              style: GoogleFonts.kalam(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.ballpointBlue,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 2),
            const HandDrawnUnderline(width: 180, isDouble: true),

            const SizedBox(height: 36),

            // Physical 2-Stage Unfolded Paper Role Chit
            TornPaperChit(
              label: 'YOUR ROLE',
              role: role,
              points: points,
              isFolded: false,
              isSelected: true,
              width: 160,
              height: 190,
            ),

            const SizedBox(height: 36),

            Text(
              'KEEP IT SECRET!',
              style: GoogleFonts.kalam(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.redInk,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Do not reveal your paper chit to other players.',
              textAlign: TextAlign.center,
              style: GoogleFonts.caveat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.pencilGrey,
              ),
            ),

            const SizedBox(height: 48),

            HandDrawnButton(
              label: 'CONTINUE TO GAME',
              pencilFillColor: AppColors.pencilBlueFill,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameScreen(roomId: roomId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
