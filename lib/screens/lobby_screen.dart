import 'package:flutter/material.dart';
import '../components/rr_loader.dart';
import '../services/room_service.dart';
import '../utils/app_theme.dart';
import '../widgets/kolam_painter.dart';
import '../widgets/traditional_card.dart';
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
          content: Text('Please enter your name to host a room'),
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
          content: Text('Failed to create room: $e'),
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
          content: Text('Please enter your name to join'),
          backgroundColor: AppColors.terracotta,
        ),
      );
      return;
    }

    if (roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-character Room ID'),
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
          content: Text('Failed to join room: $e'),
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
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: const Text(
          'RAJA RANI',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.terracotta,
        elevation: 2,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Welcome Invitation Badge
                TraditionalCard(
                  borderColor: AppColors.terracotta,
                  borderWidth: 2,
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 50,
                        height: 50,
                        child: CustomPaint(
                          painter: KolamMandalaPainter(
                            primaryColor: AppColors.terracotta,
                            secondaryColor: AppColors.turmeric,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'RAJA RANI',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkBrown,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Traditional Tamil Family Game',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.leafGreen,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Player Name Field inside invitation card
                      TextField(
                        controller: _nameController,
                        maxLength: 20,
                        style: const TextStyle(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                          labelStyle: const TextStyle(color: AppColors.darkBrown),
                          hintText: 'Enter your name',
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.person, color: AppColors.terracotta),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.borderBrown, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // CREATE ROOM CARD (Host)
                TraditionalCard(
                  borderColor: AppColors.terracotta,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.stars, color: AppColors.terracotta, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'HOST A NEW GAME',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.darkBrown,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Create a room and invite 5 family members or friends.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.darkBrown),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.terracotta,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          onPressed: _isCreatingRoom ? null : _createRoom,
                          child: _isCreatingRoom
                              ? const RRLoader(size: 24)
                              : const Text(
                                  'CREATE ROOM (HOST)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // JOIN ROOM CARD (Guest)
                TraditionalCard(
                  borderColor: AppColors.leafGreen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.meeting_room, color: AppColors.leafGreen, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'JOIN EXISTING GAME',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.darkBrown,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter the 6-character room code provided by the host.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.darkBrown),
                      ),
                      const SizedBox(height: 14),

                      // Room Code Entry Input Box
                      TextField(
                        controller: _roomIdController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 6,
                        style: const TextStyle(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 3,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'A B C 1 2 3',
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.leafGreen, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.leafGreen, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.leafGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          onPressed: _isJoiningRoom ? null : _joinRoom,
                          child: _isJoiningRoom
                              ? const RRLoader(size: 24)
                              : const Text(
                                  'JOIN GAME',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                        ),
                      ),
                    ],
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
