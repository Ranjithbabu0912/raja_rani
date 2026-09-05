import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/room_service.dart';
import '../utils/app_theme.dart';
import '../widgets/handdrawn_components.dart';
import 'room_lobby_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  final RoomService _roomService = RoomService();

  bool _isJoiningRoom = false;
  bool _isCreatingRoom = false;

  Future<void> _createRoom() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write your name in the notebook'),
          backgroundColor: AppColors.terracotta,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingRoom = true;
    });

    try {
      final roomId = await _roomService.createRoom(playerName: name);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomLobbyScreen(roomId: roomId),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create game: $e'),
          backgroundColor: AppColors.terracotta,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingRoom = false;
        });
      }
    }
  }

  Future<void> _joinRoom() async {
    final name = _nameController.text.trim();
    final roomId = _roomIdController.text.trim().toUpperCase();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write your name to join'),
          backgroundColor: AppColors.terracotta,
        ),
      );
      return;
    }

    if (roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-character room code'),
          backgroundColor: AppColors.terracotta,
        ),
      );
      return;
    }

    setState(() {
      _isJoiningRoom = true;
    });

    try {
      await _roomService.joinRoom(roomId: roomId, playerName: name);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomLobbyScreen(roomId: roomId),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join game: $e'),
          backgroundColor: AppColors.terracotta,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isJoiningRoom = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotebookPaperPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TOP TITLE HEADER: CROWNS + RAJA RANI + "KANDUPUDI?" + RED DOUBLE UNDERLINE
          Column(
            children: [
              // Two Red Hand-Drawn Crowns
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HandDrawnCrown(width: 32, height: 22),
                  SizedBox(width: 44),
                  HandDrawnCrown(width: 32, height: 22),
                ],
              ),
              const SizedBox(height: 4),

              // Title with action rays
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '\\ \\ ',
                    style: GoogleFonts.kalam(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ballpointBlue.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    'RAJA RANI',
                    style: GoogleFonts.kalam(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ballpointBlue,
                      letterSpacing: 3.0,
                    ),
                  ),
                  Text(
                    ' / /',
                    style: GoogleFonts.kalam(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ballpointBlue.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),

              // Subtitle "KANDUPUDI?"
              Text(
                '"KANDUPUDI?"',
                style: GoogleFonts.kalam(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ballpointBlue,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 4),

              // Red Double Hand-Drawn Underline
              const HandDrawnUnderline(
                width: 170,
                isDouble: true,
              ),
            ],
          ),

          const SizedBox(height: 36),

          // 2. YOUR NAME SECTION
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'YOUR NAME:',
                style: GoogleFonts.kalam(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ballpointBlue,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HandDrawnTextField(
                  controller: _nameController,
                  hintText: 'Enter your name...',
                  maxLength: 20,
                  style: GoogleFonts.patrickHand(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ballpointBlue,
                  ),
                  hintStyle: GoogleFonts.caveat(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ballpointBlue.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 38),

          // 3. WRITE NEW GAME SECTION
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Write new game',
                style: GoogleFonts.kalam(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ballpointBlue,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              const HandDrawnUnderline(
                width: 160,
                isDouble: false,
              ),
              const SizedBox(height: 8),
              Text(
                'Start a fresh notebook sheet and gather 6 players.',
                style: GoogleFonts.caveat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ballpointBlue,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: HandDrawnButton(
                  label: 'CREATE GAME (HOST)',
                  pencilFillColor: AppColors.pencilGreenFill,
                  onPressed: _createRoom,
                  isLoading: _isCreatingRoom,
                ),
              ),
            ],
          ),

          const SizedBox(height: 42),

          // 4. JOIN EXISTING GAME SECTION
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'JOIN EXISTING GAME',
                style: GoogleFonts.kalam(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ballpointBlue,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              const HandDrawnUnderline(
                width: 230,
                isDouble: false,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-character room code written in the notebook',
                style: GoogleFonts.caveat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ballpointBlue,
                ),
              ),
              const SizedBox(height: 18),

              // Room code input
              HandDrawnTextField(
                controller: _roomIdController,
                hintText: 'Enter 6-character code...',
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: GoogleFonts.kalam(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4.0,
                  color: AppColors.ballpointBlue,
                ),
                hintStyle: GoogleFonts.caveat(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ballpointBlue.withValues(alpha: 0.45),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: HandDrawnButton(
                  label: 'JOIN GAME',
                  pencilFillColor: AppColors.pencilBlueFill,
                  onPressed: _joinRoom,
                  isLoading: _isJoiningRoom,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
