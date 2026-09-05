import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/rr_loader.dart';
import '../services/room_service.dart';
import '../utils/app_theme.dart';
import '../widgets/handdrawn_components.dart';
import '../widgets/handwritten_marks.dart';
import 'game_screen.dart';

class RoomLobbyScreen extends StatefulWidget {
  final String roomId;

  const RoomLobbyScreen({super.key, required this.roomId});

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen> {
  final RoomService _roomService = RoomService();

  late final Stream<DocumentSnapshot> _roomStream;
  late final Stream<QuerySnapshot> _playersStream;
  int? _optimisticRoundsTotal;

  @override
  void initState() {
    super.initState();
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId);
    _roomStream = roomRef.snapshots();
    _playersStream = roomRef
        .collection('players')
        .orderBy('joinedAt')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _roomStream,
      builder: (context, roomSnapshot) {
        if (roomSnapshot.connectionState == ConnectionState.waiting &&
            !roomSnapshot.hasData) {
          return const NotebookPaperPage(
            child: Center(child: RRLoader(message: 'Opening Notebook...')),
          );
        }

        if (roomSnapshot.hasError && !roomSnapshot.hasData) {
          return NotebookPaperPage(
            child: Center(
              child: Text(
                'Error loading room:\n${roomSnapshot.error}',
                textAlign: TextAlign.center,
                style: GoogleFonts.patrickHand(color: AppColors.ballpointBlue, fontSize: 18),
              ),
            ),
          );
        }

        if (!roomSnapshot.hasData || !roomSnapshot.data!.exists) {
          return NotebookPaperPage(
            child: Center(
              child: Text(
                'Room no longer exists.',
                style: GoogleFonts.kalam(
                  color: AppColors.ballpointBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        final roomData = roomSnapshot.data!.data() as Map<String, dynamic>;
        final status = roomData['status'] ?? 'waiting';

        if (status == 'roleSelection' ||
            status == 'playing' ||
            status == 'round_result' ||
            status == 'completed') {
          return GameScreen(roomId: widget.roomId);
        }

        return NotebookPaperPage(
          child: _buildLobby(context, roomData),
        );
      },
    );
  }

  Widget _buildLobby(BuildContext context, Map<String, dynamic> roomData) {
    final int serverRoundsTotal = (roomData['roundsTotal'] is int)
        ? roomData['roundsTotal'] as int
        : int.tryParse(roomData['roundsTotal']?.toString() ?? '3') ?? 3;

    final int roundsTotal = _optimisticRoundsTotal ?? serverRoundsTotal;

    return StreamBuilder<QuerySnapshot>(
      stream: _playersStream,
      builder: (context, playerSnapshot) {
        if (playerSnapshot.connectionState == ConnectionState.waiting &&
            !playerSnapshot.hasData) {
          return const RRLoader(message: 'Gathering Players...');
        }

        if (playerSnapshot.hasError && !playerSnapshot.hasData) {
          return Center(
            child: Text(
              'Error loading players:\n${playerSnapshot.error}',
              textAlign: TextAlign.center,
              style: GoogleFonts.patrickHand(color: AppColors.ballpointBlue, fontSize: 18),
            ),
          );
        }

        final players = playerSnapshot.data?.docs ?? [];
        final currentUser = FirebaseAuth.instance.currentUser;
        final isHost =
            players.isNotEmpty && players.first.id == currentUser?.uid;

        return Column(
          children: [
            // ROOM CODE NOTEBOOK HEADER CARD
            CustomPaint(
              painter: _SketchyContainerPainter(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'ROOM CODE',
                      style: GoogleFonts.kalam(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: AppColors.pencilGrey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.roomId,
                      style: GoogleFonts.kalam(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6.0,
                        color: AppColors.ballpointBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share this code with friends & family to join notebook',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.caveat(
                        fontSize: 16,
                        color: AppColors.penGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ROUND SELECTOR CARD
            CustomPaint(
              painter: _SketchyContainerPainter(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NUMBER OF ROUNDS',
                          style: GoogleFonts.kalam(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ballpointBlue,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '1 – 10 notebook rounds',
                          style: GoogleFonts.caveat(
                            fontSize: 15,
                            color: AppColors.pencilGrey,
                          ),
                        ),
                      ],
                    ),
                    if (isHost)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppColors.terracotta, size: 28),
                            onPressed: roundsTotal > 1
                                ? () {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final nextVal = roundsTotal - 1;
                                    setState(() {
                                      _optimisticRoundsTotal = nextVal;
                                    });
                                    _roomService
                                        .updateRoundsTotal(
                                          roomId: widget.roomId,
                                          roundsTotal: nextVal,
                                        )
                                        .then((_) {
                                          if (mounted) {
                                            setState(() {
                                              _optimisticRoundsTotal = null;
                                            });
                                          }
                                        })
                                        .catchError((e) {
                                          if (mounted) {
                                            setState(() {
                                              _optimisticRoundsTotal = null;
                                            });
                                            messenger.showSnackBar(
                                              SnackBar(
                                                  content: Text('Error: $e')),
                                            );
                                          }
                                        });
                                  }
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$roundsTotal',
                              style: GoogleFonts.kalam(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ballpointBlue,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                color: AppColors.ballpointBlue, size: 28),
                            onPressed: roundsTotal < 10
                                ? () {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final nextVal = roundsTotal + 1;
                                    setState(() {
                                      _optimisticRoundsTotal = nextVal;
                                    });
                                    _roomService
                                        .updateRoundsTotal(
                                          roomId: widget.roomId,
                                          roundsTotal: nextVal,
                                        )
                                        .then((_) {
                                          if (mounted) {
                                            setState(() {
                                              _optimisticRoundsTotal = null;
                                            });
                                          }
                                        })
                                        .catchError((e) {
                                          if (mounted) {
                                            setState(() {
                                              _optimisticRoundsTotal = null;
                                            });
                                            messenger.showSnackBar(
                                              SnackBar(
                                                  content: Text('Error: $e')),
                                            );
                                          }
                                        });
                                  }
                                : null,
                          ),
                        ],
                      )
                    else
                      Text(
                        '$roundsTotal Rounds',
                        style: GoogleFonts.kalam(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ballpointBlue,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // PLAYERS HEADER
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WHO\'S PLAYING? (6 PLAYERS)',
                    style: GoogleFonts.kalam(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ballpointBlue,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const HandDrawnUnderline(width: 210, isDouble: false),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 6 PLAYER SLOTS WRITTEN ON NOTEBOOK LINES
            Column(
              children: List.generate(6, (index) {
                if (index < players.length) {
                  final playerData =
                      players[index].data() as Map<String, dynamic>;
                  final playerId = players[index].id;
                  final name = playerData['name'] ?? 'Player';
                  final isReady = playerData['isReady'] ?? false;
                  final isCurrentPlayer =
                      currentUser != null && currentUser.uid == playerId;

                  return _playerNotebookRow(
                    slotIndex: index + 1,
                    playerId: playerId,
                    name: name.toString(),
                    isHost: index == 0,
                    isReady: isReady == true,
                    isCurrentPlayer: isCurrentPlayer,
                  );
                }

                return _emptyPlayerNotebookRow(index + 1);
              }),
            ),

            const SizedBox(height: 28),

            // START GAME / READY CONTROL
            Builder(
              builder: (context) {
                final readyCount = players.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isReady'] == true;
                }).length;

                final canStart =
                    players.length == 6 && readyCount == 6 && isHost;

                return Column(
                  children: [
                    Text(
                      players.length < 6
                          ? 'Waiting for 6 players to gather (${players.length}/6)'
                          : '$readyCount/6 players ready!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.caveat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: readyCount == 6
                            ? AppColors.penGreen
                            : AppColors.terracotta,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: HandDrawnButton(
                        label: canStart
                            ? 'TEAR PAPERS & START GAME'
                            : players.length < 6
                                ? 'WAITING FOR 6 PLAYERS'
                                : 'WAITING FOR ALL READY',
                        onPressed: canStart
                            ? () async {
                              try {
                                await _roomService.startGame(
                                    roomId: widget.roomId);
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Unable to start game: $e')),
                                );
                              }
                            }
                          : null,
                      pencilFillColor: AppColors.pencilGreenFill,
                    ),
                  ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // DEV TEST HELPER
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.pencilGrey,
              ),
              onPressed: () async {
                try {
                  await _roomService.addSamplePlayers(
                      roomId: widget.roomId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('5 test players added to notebook.')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to add sample players: $e')),
                  );
                }
              },
              icon: const Icon(Icons.people_outline, size: 18),
              label: Text(
                'DEV: ADD 5 SAMPLE PLAYERS',
                style: GoogleFonts.caveat(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.pencilGrey,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _playerNotebookRow({
    required int slotIndex,
    required String playerId,
    required String name,
    required bool isHost,
    required bool isReady,
    required bool isCurrentPlayer,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.blueRuling, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Handwritten circle number ○ 1, ○ 2...
          Text(
            '○ $slotIndex. ',
            style: GoogleFonts.kalam(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.ballpointBlue,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  name,
                  style: GoogleFonts.patrickHand(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isCurrentPlayer
                        ? AppColors.ballpointBlue
                        : AppColors.inkBlack,
                  ),
                ),
                if (isHost) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.redInk),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'HOST',
                      style: GoogleFonts.kalam(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.redInk,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isCurrentPlayer)
            GestureDetector(
              onTap: () async {
                try {
                  await _roomService.toggleReady(
                    roomId: widget.roomId,
                    isReady: !isReady,
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to update ready status: $e')),
                  );
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isReady
                      ? AppColors.pencilGreenFill
                      : Colors.transparent,
                  border: Border.all(
                    color: isReady
                        ? AppColors.ballpointBlue
                        : AppColors.ballpointBlue,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (isReady) ...[
                      const HandwrittenCheckMark(
                          color: AppColors.ballpointBlue, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'READY',
                        style: GoogleFonts.kalam(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ballpointBlue,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'TAP READY',
                        style: GoogleFonts.kalam(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ballpointBlue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                if (isReady) ...[
                  const HandwrittenCheckMark(
                      color: AppColors.penGreen, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Ready',
                    style: GoogleFonts.caveat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.penGreen,
                    ),
                  ),
                ] else ...[
                  Text(
                    '...',
                    style: GoogleFonts.caveat(
                      fontSize: 16,
                      color: AppColors.pencilGrey,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _emptyPlayerNotebookRow(int slotIndex) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.blueRuling, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Text(
            '○ $slotIndex. ',
            style: GoogleFonts.kalam(
              fontSize: 18,
              color: AppColors.pencilGrey.withValues(alpha: 0.6),
            ),
          ),
          Text(
            'Waiting for player $slotIndex...',
            style: GoogleFonts.caveat(
              fontSize: 18,
              color: AppColors.pencilGrey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _SketchyContainerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ballpointBlue
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _SketchyContainerPainter oldDelegate) => false;
}
