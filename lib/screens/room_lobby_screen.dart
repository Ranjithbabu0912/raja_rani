import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/rr_loader.dart';
import '../services/room_service.dart';
import '../utils/app_theme.dart';
import '../widgets/traditional_card.dart';
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
          return Scaffold(
            backgroundColor: AppColors.warmCream,
            appBar: AppBar(
              title: const Text(
                'RAJA RANI',
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
              ),
              centerTitle: true,
              backgroundColor: AppColors.terracotta,
            ),
            body: const RRLoader(message: 'Loading Room...'),
          );
        }

        if (roomSnapshot.hasError && !roomSnapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.warmCream,
            appBar: AppBar(
              title: const Text(
                'RAJA RANI',
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
              ),
              centerTitle: true,
              backgroundColor: AppColors.terracotta,
            ),
            body: Center(
              child: Text(
                'Error loading room:\n${roomSnapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.darkBrown),
              ),
            ),
          );
        }

        if (!roomSnapshot.hasData || !roomSnapshot.data!.exists) {
          return Scaffold(
            backgroundColor: AppColors.warmCream,
            appBar: AppBar(
              title: const Text(
                'RAJA RANI',
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
              ),
              centerTitle: true,
              backgroundColor: AppColors.terracotta,
            ),
            body: const Center(
              child: Text(
                'Room no longer exists.',
                style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.bold),
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

        return Scaffold(
          backgroundColor: AppColors.warmCream,
          appBar: AppBar(
            title: const Text(
              'GAME LOBBY',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: AppColors.terracotta,
            elevation: 2,
          ),
          body: _buildLobby(context, roomData),
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
          return const RRLoader(message: 'Loading Players...');
        }

        if (playerSnapshot.hasError && !playerSnapshot.hasData) {
          return Center(
            child: Text(
              'Error loading players:\n${playerSnapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.darkBrown),
            ),
          );
        }

        final players = playerSnapshot.data?.docs ?? [];
        final currentUser = FirebaseAuth.instance.currentUser;
        final isHost =
            players.isNotEmpty && players.first.id == currentUser?.uid;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Column(
                children: [
                  // ROOM CODE CARD
                  TraditionalCard(
                    borderColor: AppColors.terracotta,
                    borderWidth: 2,
                    child: Column(
                      children: [
                        const Text(
                          'ROOM CODE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: AppColors.darkBrown,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.terracotta, width: 1.5),
                          ),
                          child: Text(
                            widget.roomId,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              color: AppColors.terracotta,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Share this invitation code with family and friends',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.leafGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // NUMBER OF ROUNDS SELECTOR CARD
                  TraditionalCard(
                    borderColor: AppColors.turmeric,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NUMBER OF ROUNDS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: AppColors.darkBrown,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '1 – 10 rounds',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B4838),
                              ),
                            ),
                          ],
                        ),
                        if (isHost)
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: AppColors.terracotta, size: 30),
                                onPressed: roundsTotal > 1
                                    ? () {
                                        final messenger = ScaffoldMessenger.of(context);
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
                                                  SnackBar(content: Text('Error: $e')),
                                                );
                                              }
                                            });
                                      }
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  '$roundsTotal',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.darkBrown,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: AppColors.terracotta, size: 30),
                                onPressed: roundsTotal < 10
                                    ? () {
                                        final messenger = ScaffoldMessenger.of(context);
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
                                                  SnackBar(content: Text('Error: $e')),
                                                );
                                              }
                                            });
                                      }
                                    : null,
                              ),
                            ],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.turmeric.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.turmeric),
                            ),
                            child: Text(
                              '$roundsTotal Rounds',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBrown,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // PLAYERS HEADER
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Icon(Icons.people, color: AppColors.terracotta, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'FAMILY PLAYERS (${players.length}/6)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkBrown,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 6 PLAYER SLOTS LIST
                  ...List.generate(6, (index) {
                    if (index < players.length) {
                      final playerData = players[index].data() as Map<String, dynamic>;
                      final playerId = players[index].id;
                      final name = playerData['name'] ?? 'Player';
                      final isReady = playerData['isReady'] ?? false;
                      final isCurrentPlayer = currentUser != null && currentUser.uid == playerId;

                      return _playerCard(
                        slotIndex: index + 1,
                        playerId: playerId,
                        name: name.toString(),
                        isHost: index == 0,
                        isReady: isReady == true,
                        isCurrentPlayer: isCurrentPlayer,
                      );
                    }

                    return _emptyPlayerCard(index + 1);
                  }),

                  const SizedBox(height: 18),

                  // READY STATUS & START GAME BANNER
                  Builder(
                    builder: (context) {
                      final readyCount = players.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['isReady'] == true;
                      }).length;

                      final canStart = players.length == 6 && readyCount == 6 && isHost;

                      return Column(
                        children: [
                          Text(
                            players.length < 6
                                ? 'Waiting for players to join (${players.length}/6)'
                                : '$readyCount/6 players ready',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: readyCount == 6 ? AppColors.leafGreen : AppColors.terracotta,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canStart ? AppColors.leafGreen : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: canStart ? 4 : 0,
                              ),
                              onPressed: canStart
                                  ? () async {
                                      try {
                                        await _roomService.startGame(roomId: widget.roomId);
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Unable to start game: $e')),
                                        );
                                      }
                                    }
                                  : null,
                              child: Text(
                                canStart
                                    ? 'START GAME'
                                    : players.length < 6
                                    ? 'WAITING FOR 6 PLAYERS'
                                    : 'WAITING FOR ALL READY',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // DEV / SIMULATION TEST HELPER
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkBrown,
                      side: const BorderSide(color: AppColors.terracotta, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      try {
                        await _roomService.addSamplePlayers(roomId: widget.roomId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('5 test players added.')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add sample players: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.people_alt, color: AppColors.terracotta),
                    label: const Text(
                      'DEV: ADD 5 SAMPLE PLAYERS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _playerCard({
    required int slotIndex,
    required String playerId,
    required String name,
    required bool isHost,
    required bool isReady,
    required bool isCurrentPlayer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: TraditionalCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderColor: isHost ? AppColors.terracotta : AppColors.borderBrown,
        showKolamCorners: false,
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isHost ? AppColors.terracotta : AppColors.leafGreen,
              child: Text(
                '$slotIndex',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      if (isHost) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'HOST',
                            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'Player $slotIndex',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B4838)),
                  ),
                ],
              ),
            ),
            if (isCurrentPlayer)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReady ? AppColors.leafGreen : AppColors.terracotta,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () async {
                  try {
                    await _roomService.toggleReady(
                      roomId: widget.roomId,
                      isReady: !isReady,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update ready status: $e')),
                    );
                  }
                },
                child: Text(
                  isReady ? 'READY ✓' : 'TAP READY',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isReady ? AppColors.leafGreen.withValues(alpha: 0.15) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isReady ? AppColors.leafGreen : Colors.grey),
                ),
                child: Text(
                  isReady ? 'READY ✓' : 'WAITING',
                  style: TextStyle(
                    color: isReady ? AppColors.leafGreen : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyPlayerCard(int slotIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: TraditionalCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: Colors.white.withValues(alpha: 0.7),
        borderColor: Colors.grey.shade300,
        showKolamCorners: false,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                '$slotIndex',
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Waiting for Player $slotIndex...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
