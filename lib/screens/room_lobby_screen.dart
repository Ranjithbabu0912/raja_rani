import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/room_service.dart';
import 'role_screen.dart';

class RoomLobbyScreen extends StatefulWidget {
  final String roomId;

  const RoomLobbyScreen({super.key, required this.roomId});

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen> {
  final RoomService _roomService = RoomService();

  @override
  Widget build(BuildContext context) {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId);

    return Scaffold(
      appBar: AppBar(title: const Text('Raja Rani'), centerTitle: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream: roomRef.snapshots(),
        builder: (context, roomSnapshot) {
          if (roomSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (roomSnapshot.hasError) {
            return Center(
              child: Text(
                'Error loading room:\n${roomSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!roomSnapshot.hasData || !roomSnapshot.data!.exists) {
            return const Center(child: Text('Room no longer exists.'));
          }

          final roomData = roomSnapshot.data!.data() as Map<String, dynamic>;

          final status = roomData['status'] ?? 'waiting';

          if (status == 'playing' || status == 'round_result' || status == 'completed') {
            return _buildRoleScreen();
          }

          return _buildLobby(context, roomRef, roomData);
        },
      ),
    );
  }

  Widget _buildLobby(
    BuildContext context,
    DocumentReference roomRef,
    Map<String, dynamic> roomData,
  ) {
    final int roundsTotal = (roomData['roundsTotal'] is int)
        ? roomData['roundsTotal'] as int
        : int.tryParse(roomData['roundsTotal']?.toString() ?? '3') ?? 3;

    return StreamBuilder<QuerySnapshot>(
      stream: roomRef.collection('players').orderBy('joinedAt').snapshots(),
      builder: (context, playerSnapshot) {
        if (playerSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (playerSnapshot.hasError) {
          return Center(
            child: Text(
              'Error loading players:\n${playerSnapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final players = playerSnapshot.data?.docs ?? [];
        final currentUser = FirebaseAuth.instance.currentUser;
        final isHost = players.isNotEmpty && players.first.id == currentUser?.uid;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Column(
                children: [
                  const Text(
                    'GAME LOBBY',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // ROOM CODE
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'ROOM CODE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.roomId,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Share this code with your friends'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // NUMBER OF ROUNDS SELECTOR CARD
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '1 – 10 rounds',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          if (isHost)
                            Row(
                              children: [
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.remove),
                                  onPressed: roundsTotal > 1
                                      ? () async {
                                          try {
                                            await _roomService.updateRoundsTotal(
                                              roomId: widget.roomId,
                                              roundsTotal: roundsTotal - 1,
                                            );
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $e')),
                                            );
                                          }
                                        }
                                      : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    '$roundsTotal',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.add),
                                  onPressed: roundsTotal < 10
                                      ? () async {
                                          try {
                                            await _roomService.updateRoundsTotal(
                                              roomId: widget.roomId,
                                              roundsTotal: roundsTotal + 1,
                                            );
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $e')),
                                            );
                                          }
                                        }
                                      : null,
                                ),
                              ],
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$roundsTotal Rounds',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PLAYER COUNT
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PLAYERS (${players.length}/6)',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // PLAYER LIST
                  ...List.generate(6, (index) {
                    if (index < players.length) {
                      final playerData =
                          players[index].data() as Map<String, dynamic>;

                      final playerId = players[index].id;

                      final name = playerData['name'] ?? 'Player';

                      final isReady = playerData['isReady'] ?? false;

                      final currentUser = FirebaseAuth.instance.currentUser;

                      final isCurrentPlayer =
                          currentUser != null && currentUser.uid == playerId;

                      return _playerCard(
                        playerId: playerId,
                        name: name.toString(),
                        isHost: index == 0,
                        isReady: isReady == true,
                        isCurrentPlayer: isCurrentPlayer,
                      );
                    }

                    return _emptyPlayerCard(index);
                  }),

                  const SizedBox(height: 20),

                  // READY COUNT / STATUS
                  Builder(
                    builder: (context) {
                      final readyCount = players.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        return data['isReady'] == true;
                      }).length;

                      if (players.length < 6) {
                        return Text(
                          'Waiting for players... '
                          '(${players.length}/6)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }

                      return Text(
                        '$readyCount/6 players ready',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: readyCount == 6 ? Colors.green : Colors.orange,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // START GAME
                  Builder(
                    builder: (context) {
                      final currentUser = FirebaseAuth.instance.currentUser;

                      final isHost =
                          players.isNotEmpty &&
                          players.first.id == currentUser?.uid;

                      final readyCount = players.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        return data['isReady'] == true;
                      }).length;

                      final canStart =
                          players.length == 6 && readyCount == 6 && isHost;

                      return SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: canStart
                              ? () async {
                                  try {
                                    await _roomService.startGame(
                                      roomId: widget.roomId,
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Unable to start game: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          child: Text(
                            canStart
                                ? 'START GAME'
                                : players.length < 6
                                ? 'WAITING FOR PLAYERS'
                                : 'WAITING FOR ALL PLAYERS',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await _roomService.addSamplePlayers(
                          roomId: widget.roomId,
                        );

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('5 sample players added.'),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add sample players: $e'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.people),
                    label: const Text('ADD 5 SAMPLE PLAYERS'),
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
    required String playerId,
    required String name,
    required bool isHost,
    required bool isReady,
    required bool isCurrentPlayer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(child: Icon(isHost ? Icons.star : Icons.person)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: isHost ? const Text('HOST') : null,
        trailing: isCurrentPlayer
            ? OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                      SnackBar(
                        content: Text('Failed to update ready status: $e'),
                      ),
                    );
                  }
                },
                child: Text(isReady ? 'READY ✓' : 'READY'),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  isReady ? 'READY ✓' : 'NOT READY',
                  style: TextStyle(
                    color: isReady ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _emptyPlayerCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(
          'Waiting for Player ${index + 1}',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildRoleScreen() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Player is not authenticated.'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('players')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Player data not found.'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final role = data['role'] ?? '';

        final points = data['rolePoints'] ?? 0;

        if (role.toString().isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RoleScreen(
          roomId: widget.roomId,
          role: role.toString(),
          points: points is int ? points : int.tryParse(points.toString()) ?? 0,
        );
      },
    );
  }
}
