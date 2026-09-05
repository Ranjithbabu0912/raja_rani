import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/card_selection_widget.dart';
import '../components/rr_loader.dart';
import '../services/room_service.dart';
import '../utils/app_theme.dart';
import '../widgets/kolam_painter.dart';
import '../widgets/traditional_card.dart';

class GameScreen extends StatefulWidget {
  final String roomId;

  const GameScreen({super.key, required this.roomId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final RoomService _roomService = RoomService();

  String? _selectedPlayerId;
  bool _isProcessingGuess = false;

  // Toggle for Developer / Test mode controls
  bool _isDevTestMode = false;
  bool _isAllPlayersTestView = false;

  late final Stream<DocumentSnapshot> _roomStream;
  late final Stream<QuerySnapshot> _playersStream;

  @override
  void initState() {
    super.initState();
    final roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    _roomStream = roomRef.snapshots();
    _playersStream =
        roomRef.collection('players').orderBy('joinedAt').snapshots();
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'raja':
        return Icons.workspace_premium;
      case 'rani':
        return Icons.favorite;
      case 'manthiri':
        return Icons.person;
      case 'sippai':
        return Icons.shield;
      case 'police':
        return Icons.local_police;
      case 'thirudan':
        return Icons.visibility_off;
      default:
        return Icons.person;
    }
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
        return AppColors.darkBrown;
    }
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
                'RAJA RANI GAME',
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
              ),
              centerTitle: true,
              backgroundColor: AppColors.terracotta,
            ),
            body: const RRLoader(message: 'Loading Room...'),
          );
        }

        if (roomSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Raja Rani Game'),
              centerTitle: true,
              backgroundColor: Colors.indigo.shade800,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Text(
                'Error loading room:\n${roomSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!roomSnapshot.hasData || !roomSnapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Raja Rani Game'),
              centerTitle: true,
              backgroundColor: Colors.indigo.shade800,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: Text('Room not found.')),
          );
        }

        final roomData = roomSnapshot.data!.data() as Map<String, dynamic>;

        final String status = roomData['status']?.toString() ?? 'waiting';
        final String currentTurnPlayerId =
            roomData['currentTurnPlayerId']?.toString() ??
            roomData['currentRajaId']?.toString() ??
            '';
        final String currentRole =
            roomData['currentRole']?.toString() ?? 'Raja';
        final String currentTargetRole =
            roomData['currentTargetRole']?.toString() ?? 'Rani';
        final List<String> completedRoles = List<String>.from(
          (roomData['completedRoles'] as List<dynamic>?)
                  ?.map((e) => e.toString()) ??
              [],
        );
        final Map<String, dynamic>? lastAction =
            roomData['lastAction'] is Map<String, dynamic>
                ? roomData['lastAction'] as Map<String, dynamic>
                : null;
        final String? lastActionMessage =
            roomData['lastActionMessage']?.toString();

        final int currentRound = (roomData['currentRound'] is int)
            ? roomData['currentRound'] as int
            : (roomData['round'] is int)
                ? roomData['round'] as int
                : int.tryParse(roomData['currentRound']?.toString() ?? roomData['round']?.toString() ?? '1') ?? 1;

        final int roundsTotal = (roomData['roundsTotal'] is int)
            ? roomData['roundsTotal'] as int
            : int.tryParse(roomData['roundsTotal']?.toString() ?? '3') ?? 3;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Raja Rani Game',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ROUND $currentRound / $roundsTotal',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            centerTitle: true,
            backgroundColor: AppColors.terracotta,
            foregroundColor: Colors.white,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'toggle_dev_mode') {
                    setState(() {
                      _isDevTestMode = !_isDevTestMode;
                      if (!_isDevTestMode) {
                        _isAllPlayersTestView = false;
                        final currentUid =
                            FirebaseAuth.instance.currentUser?.uid;
                        if (currentUid != null) {
                          _selectedPlayerId = currentUid;
                        }
                      }
                    });
                  } else if (value == 'toggle_all_view') {
                    setState(() {
                      _isAllPlayersTestView = !_isAllPlayersTestView;
                    });
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle_dev_mode',
                    child: Row(
                      children: [
                        Icon(
                          _isDevTestMode ? Icons.build_circle : Icons.build,
                          color: Colors.indigo,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(_isDevTestMode
                            ? 'Disable Dev Test Mode'
                            : 'Enable Dev Test Mode'),
                      ],
                    ),
                  ),
                  if (_isDevTestMode)
                    PopupMenuItem(
                      value: 'toggle_all_view',
                      child: Row(
                        children: [
                          Icon(
                            _isAllPlayersTestView
                                ? Icons.person_pin
                                : Icons.grid_view_rounded,
                            color: Colors.indigo,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(_isAllPlayersTestView
                              ? 'Single Player View'
                              : 'All 6 Players View'),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _playersStream,
            builder: (context, playersSnapshot) {
              if (playersSnapshot.connectionState == ConnectionState.waiting &&
                  !playersSnapshot.hasData) {
                return const RRLoader(message: 'Loading Players...');
              }

              if (playersSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading players:\n${playersSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final players = playersSnapshot.data?.docs ?? [];

              if (players.isEmpty) {
                return const Center(child: Text('No players found.'));
              }

              if (status == 'roleSelection') {
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                if (_selectedPlayerId == null ||
                    !players.any((player) => player.id == _selectedPlayerId)) {
                  if (currentUserId != null &&
                      players.any((player) => player.id == currentUserId)) {
                    _selectedPlayerId = currentUserId;
                  } else {
                    _selectedPlayerId = players.first.id;
                  }
                }

                return CardSelectionWidget(
                  roomId: widget.roomId,
                  roomData: roomData,
                  players: players,
                  activePlayerId: _selectedPlayerId!,
                  isDevTestMode: _isDevTestMode,
                  onPlayerSwitched: (newPlayerId) {
                    setState(() {
                      _selectedPlayerId = newPlayerId;
                    });
                  },
                );
              }

              if (status == 'round_result') {
                return _buildRoundResultScreen(
                  context,
                  players,
                  roomData,
                  currentRound,
                  roundsTotal,
                );
              }

              if (status == 'completed') {
                return _buildFinalScoreboardScreen(
                  context,
                  players,
                  roomData,
                  roundsTotal,
                );
              }

              // Multi-Device Mode: Default to current authenticated user's ID
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;

              if (_selectedPlayerId == null ||
                  !players.any((player) => player.id == _selectedPlayerId)) {
                if (currentUserId != null &&
                    players.any((player) => player.id == currentUserId)) {
                  _selectedPlayerId = currentUserId;
                } else {
                  _selectedPlayerId = players.first.id;
                }
              }

              final selectedPlayerDoc = players.firstWhere(
                (player) => player.id == _selectedPlayerId,
              );

              final selectedData =
                  selectedPlayerDoc.data() as Map<String, dynamic>;
              final selectedName =
                  selectedData['name']?.toString() ?? 'Player';
              final selectedRole = selectedData['role']?.toString() ?? '';
              final selectedPoints = (selectedData['rolePoints'] is int)
                  ? selectedData['rolePoints'] as int
                  : int.tryParse(selectedData['rolePoints']?.toString() ?? '0') ?? 0;
              final selectedRoundScore = (selectedData['roundScore'] is int)
                  ? selectedData['roundScore'] as int
                  : int.tryParse(selectedData['roundScore']?.toString() ?? '0') ?? 0;
              final selectedScore = (selectedData['score'] is int)
                  ? selectedData['score'] as int
                  : int.tryParse(selectedData['score']?.toString() ?? '0') ?? 0;

              final isMyTurn = selectedPlayerDoc.id == currentTurnPlayerId;
              final currentTurnPlayerName =
                  _getPlayerName(players, currentTurnPlayerId);

              if (_isDevTestMode && _isAllPlayersTestView) {
                return _buildAllPlayersDashboard(
                  context: context,
                  players: players,
                  currentTurnPlayerId: currentTurnPlayerId,
                  currentRole: currentRole,
                  currentTargetRole: currentTargetRole,
                  completedRoles: completedRoles,
                  lastAction: lastAction,
                  lastActionMessage: lastActionMessage,
                  currentRound: currentRound,
                  roundsTotal: roundsTotal,
                );
              }

              return _buildActiveGame(
                context: context,
                players: players,
                selectedPlayerId: selectedPlayerDoc.id,
                selectedPlayerName: selectedName,
                selectedRole: selectedRole,
                selectedPoints: selectedPoints,
                selectedRoundScore: selectedRoundScore,
                selectedScore: selectedScore,
                isMyTurn: isMyTurn,
                currentTurnPlayerId: currentTurnPlayerId,
                currentTurnPlayerName: currentTurnPlayerName,
                currentRole: currentRole,
                currentTargetRole: currentTargetRole,
                completedRoles: completedRoles,
                lastAction: lastAction,
                lastActionMessage: lastActionMessage,
                currentRound: currentRound,
                roundsTotal: roundsTotal,
              );
            },
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // ROUND RESULT SCREEN (Displayed to all players at end of each round)
  // --------------------------------------------------------------------------
  Widget _buildRoundResultScreen(
    BuildContext context,
    List<QueryDocumentSnapshot> players,
    Map<String, dynamic> roomData,
    int currentRound,
    int roundsTotal,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isHost = players.isNotEmpty && players.first.id == currentUser?.uid;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              color: Colors.indigo.shade800,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.stars_rounded, size: 50, color: Colors.amber),
                    const SizedBox(height: 8),
                    Text(
                      'ROUND $currentRound RESULT',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Round $currentRound of $roundsTotal completed',
                      style: TextStyle(fontSize: 14, color: Colors.indigo.shade100),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ROUND SCOREBOARD',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Divider(height: 20),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2.5),
                        1: FlexColumnWidth(1.5),
                        2: FlexColumnWidth(1.5),
                      },
                      children: [
                        const TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Player',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Round Score',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Overall Score',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...players.map((playerDoc) {
                          final data = playerDoc.data() as Map<String, dynamic>;
                          final name = data['name']?.toString() ?? 'Player';
                          final role = data['role']?.toString() ?? '';
                          final roundScore = (data['roundScore'] is int)
                              ? data['roundScore'] as int
                              : int.tryParse(data['roundScore']?.toString() ?? '0') ?? 0;
                          final overallScore = (data['score'] is int)
                              ? data['score'] as int
                              : int.tryParse(data['score']?.toString() ?? '0') ?? 0;

                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (role.isNotEmpty)
                                      Text(
                                        role.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  '+$roundScore',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  '$overallScore',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (isHost || _isDevTestMode)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      await _roomService.startNextRound(roomId: widget.roomId);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error starting next round: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    'START ROUND ${currentRound + 1} OF $roundsTotal',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Waiting for host to start Round ${currentRound + 1}...',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // FINAL SCOREBOARD & WINNER SCREEN
  // --------------------------------------------------------------------------
  Widget _buildFinalScoreboardScreen(
    BuildContext context,
    List<QueryDocumentSnapshot> playersSnapshotDocs,
    Map<String, dynamic> roomData,
    int roundsTotal,
  ) {
    final Map<String, String> playerNames = {};
    final Map<String, Map<int, int>> playerRoundScores = {};
    final Map<String, int> playerTotalScores = {};

    for (final pDoc in playersSnapshotDocs) {
      final pData = pDoc.data() as Map<String, dynamic>;
      final pId = pDoc.id;
      final pName = pData['name']?.toString() ?? 'Player';
      final pScore = (pData['score'] is int)
          ? pData['score'] as int
          : int.tryParse(pData['score']?.toString() ?? '0') ?? 0;

      playerNames[pId] = pName;
      playerRoundScores[pId] = {};
      playerTotalScores[pId] = pScore;
    }

    final Map<String, dynamic> roundHistoryMap =
        (roomData['roundHistory'] is Map<String, dynamic>)
            ? roomData['roundHistory'] as Map<String, dynamic>
            : {};

    int maxRoundNumber = roundsTotal;

    roundHistoryMap.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final int rNum = (value['roundNumber'] is int)
            ? value['roundNumber'] as int
            : int.tryParse(value['roundNumber']?.toString() ?? '1') ?? 1;

        if (rNum > maxRoundNumber) maxRoundNumber = rNum;

        final rPlayers = value['players'] as List<dynamic>? ?? [];

        for (final pItem in rPlayers) {
          if (pItem is Map<String, dynamic>) {
            final pId = pItem['playerId']?.toString() ?? '';
            final pName = pItem['name']?.toString() ?? '';
            final rScore = (pItem['roundScore'] is int)
                ? pItem['roundScore'] as int
                : int.tryParse(pItem['roundScore']?.toString() ?? '0') ?? 0;

            if (pId.isNotEmpty) {
              if (pName.isNotEmpty) playerNames[pId] = pName;
              playerRoundScores.putIfAbsent(pId, () => {})[rNum] = rScore;
            }
          }
        }
      }
    });

    // Sort players by Total Score DESC
    final sortedPlayerIds = playerNames.keys.toList()
      ..sort((a, b) {
        final scoreA = playerTotalScores[a] ?? 0;
        final scoreB = playerTotalScores[b] ?? 0;
        if (scoreB != scoreA) {
          return scoreB.compareTo(scoreA);
        }
        return (playerNames[a] ?? '').compareTo(playerNames[b] ?? '');
      });

    final winnerId = sortedPlayerIds.isNotEmpty ? sortedPlayerIds.first : '';
    final winnerName = playerNames[winnerId] ?? 'Player';
    final winnerScore = playerTotalScores[winnerId] ?? 0;

    final int actualRoundCount = maxRoundNumber;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // WINNER CARD
                TraditionalCard(
                  backgroundColor: AppColors.cardCream,
                  borderColor: AppColors.terracotta,
                  borderWidth: 2.5,
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 60,
                        height: 60,
                        child: CustomPaint(
                          painter: KolamMandalaPainter(
                            primaryColor: AppColors.terracotta,
                            secondaryColor: AppColors.turmeric,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '🏆 WINNER 🏆',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          color: AppColors.terracotta,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        winnerName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Score: $winnerScore Points',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.leafGreen,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // FINAL SCOREBOARD TABLE CARD
                TraditionalCard(
                  borderColor: AppColors.turmeric,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.leaderboard, color: AppColors.terracotta),
                          SizedBox(width: 8),
                          Text(
                            'FINAL SCOREBOARD',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: AppColors.darkBrown,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: AppColors.borderBrown),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 16,
                          headingRowHeight: 40,
                          columns: [
                            const DataColumn(
                              label: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
                            ),
                            const DataColumn(
                              label: Text('Player', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
                            ),
                            ...List.generate(actualRoundCount, (index) {
                              return DataColumn(
                                label: Text(
                                  'Round ${index + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBrown),
                                ),
                              );
                            }),
                            const DataColumn(
                              label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
                            ),
                          ],
                          rows: sortedPlayerIds.asMap().entries.map((entry) {
                            final rank = entry.key + 1;
                            final pId = entry.value;
                            final pName = playerNames[pId] ?? 'Player';
                            final pTotal = playerTotalScores[pId] ?? 0;
                            final pRoundsMap = playerRoundScores[pId] ?? {};

                            String medal = '';
                            if (rank == 1) medal = '🥇 ';
                            if (rank == 2) medal = '🥈 ';
                            if (rank == 3) medal = '🥉 ';

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    '$medal#$rank',
                                    style: TextStyle(
                                      fontWeight: rank == 1 ? FontWeight.bold : FontWeight.normal,
                                      color: AppColors.darkBrown,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    pName,
                                    style: TextStyle(
                                      fontWeight: rank == 1 ? FontWeight.bold : FontWeight.normal,
                                      color: AppColors.darkBrown,
                                    ),
                                  ),
                                ),
                                ...List.generate(actualRoundCount, (index) {
                                  final rNum = index + 1;
                                  final rScore = pRoundsMap[rNum] ?? 0;
                                  return DataCell(Text('+$rScore', style: const TextStyle(color: AppColors.darkBrown)));
                                }),
                                DataCell(
                                  Text(
                                    '$pTotal',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.leafGreen,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text(
                      'BACK TO LOBBY',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }

  // --------------------------------------------------------------------------
  // ALL 6 PLAYERS DASHBOARD TEST VIEW (DEV MODE ONLY)
  // --------------------------------------------------------------------------
  Widget _buildAllPlayersDashboard({
    required BuildContext context,
    required List<QueryDocumentSnapshot> players,
    required String currentTurnPlayerId,
    required String currentRole,
    required String currentTargetRole,
    required List<String> completedRoles,
    required Map<String, dynamic>? lastAction,
    required String? lastActionMessage,
    required int currentRound,
    required int roundsTotal,
  }) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Mode Banner & Mode Switch Button
            Card(
              color: Colors.amber.shade100,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.dashboard_customize,
                        color: Colors.amber, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'ALL 6 PLAYERS DASHBOARD',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.indigo,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'ROUND $currentRound / $roundsTotal',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Control all 6 players simultaneously on one screen.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 36),
                      ),
                      onPressed: () {
                        setState(() {
                          _isAllPlayersTestView = false;
                        });
                      },
                      child: const Text('SINGLE VIEW',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Live Game Announcement
            if (lastActionMessage != null && lastActionMessage.isNotEmpty)
              Card(
                elevation: 2,
                color: _getActionResultBgColor(lastAction),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _getActionResultIcon(lastAction),
                        color: _getActionResultTextColor(lastAction),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lastActionMessage,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _getActionResultTextColor(lastAction),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // 6 Players Cards Grid
            ...players.map((playerDoc) {
              final data = playerDoc.data() as Map<String, dynamic>;
              final playerId = playerDoc.id;
              final name = data['name']?.toString() ?? 'Player';
              final role = data['role']?.toString() ?? '';
              final rolePoints = (data['rolePoints'] is int)
                  ? data['rolePoints'] as int
                  : int.tryParse(data['rolePoints']?.toString() ?? '0') ?? 0;
              final score = (data['score'] is int)
                  ? data['score'] as int
                  : int.tryParse(data['score']?.toString() ?? '0') ?? 0;

              final isTurn = playerId == currentTurnPlayerId;
              final isCompleted = completedRoles
                  .map((r) => r.toLowerCase())
                  .contains(role.toLowerCase());
              final roleColor = _getRoleColor(role);

              // Candidate targets for guessing: exclude self and exclude already completed roles
              final guessableTargets = players.where((p) {
                if (p.id == playerId) return false;
                final pData = p.data() as Map<String, dynamic>;
                final pRole = pData['role']?.toString() ?? '';
                final pCompleted = completedRoles
                    .map((r) => r.toLowerCase())
                    .contains(pRole.toLowerCase());
                return !pCompleted;
              }).toList();

              return Card(
                elevation: isTurn ? 5 : 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isTurn
                        ? Colors.amber.shade700
                        : isCompleted
                            ? Colors.green.shade600
                            : Colors.grey.shade300,
                    width: isTurn || isCompleted ? 2.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: roleColor.withValues(alpha: 0.15),
                            child: Icon(_getRoleIcon(role),
                                size: 20, color: roleColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isTurn) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade700,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          '👉 ACTIVE TURN',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ] else if (isCompleted) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade700,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'COMPLETED ✓',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  'Role: ${role.toUpperCase()} ($rolePoints pts) | Total Score: $score pts',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: roleColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (isTurn) ...[
                        const Divider(height: 16),
                        Text(
                          'YOUR TURN ($currentRole): Tap player to guess who is $currentTargetRole:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (guessableTargets.isEmpty)
                          const Text(
                            'No valid targets remaining.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: guessableTargets.map((targetDoc) {
                              final targetData =
                                  targetDoc.data() as Map<String, dynamic>;
                              final targetName =
                                  targetData['name']?.toString() ?? 'Player';

                              return ActionChip(
                                avatar: const Icon(Icons.touch_app, size: 14),
                                label: Text('Guess $targetName'),
                                backgroundColor: Colors.indigo.shade50,
                                labelStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                                onPressed: _isProcessingGuess
                                    ? null
                                    : () {
                                        _confirmGuess(
                                          context: context,
                                          targetPlayerId: targetDoc.id,
                                          targetPlayerName: targetName,
                                          guessingPlayerId: playerId,
                                          currentTargetRole: currentTargetRole,
                                        );
                                      },
                              );
                            }).toList(),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // MULTI-DEVICE PRODUCTION GAME VIEW
  // --------------------------------------------------------------------------
  Widget _buildActiveGame({
    required BuildContext context,
    required List<QueryDocumentSnapshot> players,
    required String selectedPlayerId,
    required String selectedPlayerName,
    required String selectedRole,
    required int selectedPoints,
    required int selectedRoundScore,
    required int selectedScore,
    required bool isMyTurn,
    required String currentTurnPlayerId,
    required String currentTurnPlayerName,
    required String currentRole,
    required String currentTargetRole,
    required List<String> completedRoles,
    required Map<String, dynamic>? lastAction,
    required String? lastActionMessage,
    required int currentRound,
    required int roundsTotal,
  }) {
    final roleIcon = _getRoleIcon(selectedRole);
    final roleColor = _getRoleColor(selectedRole);

    // Candidates to guess: exclude self and exclude players whose role is already completed
    final validGuessablePlayers = players.where((player) {
      if (player.id == selectedPlayerId) return false;
      final data = player.data() as Map<String, dynamic>;
      final playerRole = data['role']?.toString() ?? '';
      final isCompleted = completedRoles
          .map((r) => r.toLowerCase())
          .contains(playerRole.toLowerCase());
      return !isCompleted;
    }).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --------------------------------------------------
            // DEV TEST MODE SWITCHER (Only shown when Dev Mode enabled)
            // --------------------------------------------------
            if (_isDevTestMode)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.phonelink_setup,
                                  size: 18, color: Colors.indigo),
                              SizedBox(width: 8),
                              Text(
                                'DEV TEST MODE — SWITCH VIEW',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isAllPlayersTestView = true;
                              });
                            },
                            icon: const Icon(Icons.grid_view_rounded, size: 16),
                            label: const Text('ALL 6 VIEW',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPlayerId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          prefixIcon: Icon(Icons.person_pin),
                        ),
                        items: players.map((player) {
                          final data = player.data() as Map<String, dynamic>;
                          final name = data['name']?.toString() ?? 'Player';
                          final pRole = data['role']?.toString() ?? '';
                          final isTurn = player.id == currentTurnPlayerId;
                          final isCompleted = completedRoles
                              .map((r) => r.toLowerCase())
                              .contains(pRole.toLowerCase());

                          return DropdownMenuItem<String>(
                            value: player.id,
                            child: Text(
                              isTurn
                                  ? '$name  [👉 CURRENT TURN: $currentRole]'
                                  : isCompleted
                                      ? '$name  [✓ COMPLETED]'
                                      : name,
                              style: TextStyle(
                                fontWeight: isTurn
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isTurn
                                    ? Colors.green.shade800
                                    : isCompleted
                                        ? Colors.grey
                                        : null,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedPlayerId = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

            if (_isDevTestMode) const SizedBox(height: 16),

            // --------------------------------------------------
            // 1. SECRET ROLE & SCORE CARD
            // --------------------------------------------------
            Card(
              elevation: 4,
              color: Colors.indigo.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: roleColor, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 16, color: roleColor),
                        const SizedBox(width: 6),
                        Text(
                          'YOUR SECRET ROLE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.8,
                            color: roleColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: roleColor.withValues(alpha: 0.15),
                      child: Icon(roleIcon, size: 36, color: roleColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedRole.isEmpty
                          ? 'ROLE NOT ASSIGNED'
                          : selectedRole.toUpperCase(),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Role Points',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$selectedPoints',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                            height: 30, width: 1, color: Colors.grey.shade400),
                        Column(
                          children: [
                            const Text(
                              'Round Score',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+$selectedRoundScore',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                        Container(
                            height: 30, width: 1, color: Colors.grey.shade400),
                        Column(
                          children: [
                            const Text(
                              'Total Score',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$selectedScore',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // 2. SYNCHRONIZED GLOBAL GUESS RESULT BANNER
            // --------------------------------------------------
            if (lastActionMessage != null && lastActionMessage.isNotEmpty)
              Card(
                elevation: 3,
                color: _getActionResultBgColor(lastAction),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        _getActionResultIcon(lastAction),
                        color: _getActionResultTextColor(lastAction),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LATEST GAME ACTION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: _getActionResultTextColor(lastAction),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastActionMessage,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _getActionResultTextColor(lastAction),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // 3. CURRENT TURN STATUS & GUESSING AREA
            // --------------------------------------------------
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (isMyTurn) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade700),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars, color: Colors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'YOUR TURN! Find the $currentTargetRole',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Select who you think is the $currentTargetRole:',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (validGuessablePlayers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No valid guessable players remaining.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        )
                      else
                        ...validGuessablePlayers.map((player) {
                          final data = player.data() as Map<String, dynamic>;
                          final name = data['name']?.toString() ?? 'Player';

                          return _playerGuessTile(
                            context: context,
                            targetPlayerId: player.id,
                            targetPlayerName: name,
                            guessingPlayerId: selectedPlayerId,
                            currentTargetRole: currentTargetRole,
                          );
                        }),
                    ] else ...[
                      const Icon(Icons.hourglass_top_rounded,
                          size: 54, color: Colors.indigo),
                      const SizedBox(height: 12),
                      Text(
                        'Waiting for $currentTurnPlayerName ($currentRole)...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$currentTurnPlayerName is currently looking for the $currentTargetRole.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // 4. ROOM PLAYERS LIST SUMMARY
            // --------------------------------------------------
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PLAYERS IN ROOM',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...players.map((player) {
                      final data = player.data() as Map<String, dynamic>;
                      final name = data['name']?.toString() ?? 'Player';
                      final pRole = data['role']?.toString() ?? '';
                      final score = (data['score'] is int)
                          ? data['score'] as int
                          : int.tryParse(data['score']?.toString() ?? '0') ?? 0;
                      final isTurn = player.id == currentTurnPlayerId;
                      final isMe = player.id == selectedPlayerId;
                      final isCompleted = completedRoles
                          .map((r) => r.toLowerCase())
                          .contains(pRole.toLowerCase());

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 10),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isTurn
                              ? Colors.amber.shade50
                              : isMe
                                  ? Colors.indigo.shade50
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: isTurn
                              ? Border.all(color: Colors.amber.shade600)
                              : isCompleted
                                  ? Border.all(color: Colors.green.shade400)
                                  : null,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: isTurn
                                  ? Colors.amber
                                  : isCompleted
                                      ? Colors.green
                                      : isMe
                                          ? Colors.indigo
                                          : Colors.grey,
                              child: Icon(
                                isTurn
                                    ? Icons.stars
                                    : isCompleted
                                        ? Icons.check
                                        : Icons.person,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isMe ? '$name (You)' : name,
                                style: TextStyle(
                                  fontWeight: isTurn || isMe
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isTurn)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade700,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  currentRole,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else if (isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'COMPLETED ✓',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Text(
                              '$score pts',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerGuessTile({
    required BuildContext context,
    required String targetPlayerId,
    required String targetPlayerName,
    required String guessingPlayerId,
    required String currentTargetRole,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade100,
          child: const Icon(Icons.person, color: Colors.indigo),
        ),
        title: Text(
          targetPlayerName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Guess as $currentTargetRole'),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          onPressed: _isProcessingGuess
              ? null
              : () {
                  _confirmGuess(
                    context: context,
                    targetPlayerId: targetPlayerId,
                    targetPlayerName: targetPlayerName,
                    guessingPlayerId: guessingPlayerId,
                    currentTargetRole: currentTargetRole,
                  );
                },
          child: const Text('GUESS'),
        ),
      ),
    );
  }

  void _confirmGuess({
    required BuildContext context,
    required String targetPlayerId,
    required String targetPlayerName,
    required String guessingPlayerId,
    required String currentTargetRole,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Your Guess'),
          content: Text(
            'Do you think $targetPlayerName is the $currentTargetRole?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _submitGuess(
                  guessingPlayerId: guessingPlayerId,
                  targetPlayerId: targetPlayerId,
                );
              },
              child: const Text('CONFIRM'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitGuess({
    required String guessingPlayerId,
    required String targetPlayerId,
  }) async {
    if (_isProcessingGuess) return;

    setState(() {
      _isProcessingGuess = true;
    });

    try {
      final result = await _roomService.makeGuess(
        roomId: widget.roomId,
        guessingPlayerId: guessingPlayerId,
        targetPlayerId: targetPlayerId,
      );

      if (!mounted) return;

      final bool isCorrect = result['isCorrect'] == true;
      final String message = result['message']?.toString() ?? '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isCorrect ? Colors.green : Colors.orange.shade800,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingGuess = false;
        });
      }
    }
  }

  String _getPlayerName(
      List<QueryDocumentSnapshot> players, String playerId) {
    for (final player in players) {
      if (player.id == playerId) {
        final data = player.data() as Map<String, dynamic>;
        return data['name']?.toString() ?? 'Player';
      }
    }
    return 'Player';
  }

  Color _getActionResultBgColor(Map<String, dynamic>? lastAction) {
    if (lastAction == null) return Colors.blue.shade50;
    final result = lastAction['result']?.toString();
    if (result == 'correct') return Colors.green.shade50;
    if (result == 'wrong') return Colors.orange.shade50;
    return Colors.blue.shade50;
  }

  Color _getActionResultTextColor(Map<String, dynamic>? lastAction) {
    if (lastAction == null) return Colors.blue.shade900;
    final result = lastAction['result']?.toString();
    if (result == 'correct') return Colors.green.shade900;
    if (result == 'wrong') return Colors.orange.shade900;
    return Colors.blue.shade900;
  }

  IconData _getActionResultIcon(Map<String, dynamic>? lastAction) {
    if (lastAction == null) return Icons.info_outline;
    final result = lastAction['result']?.toString();
    if (result == 'correct') return Icons.check_circle_outline;
    if (result == 'wrong') return Icons.swap_horizontal_circle_outlined;
    return Icons.info_outline;
  }
}
