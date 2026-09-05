import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/card_selection_widget.dart';
import '../components/rr_loader.dart';
import '../services/room_service.dart';
import '../utils/app_theme.dart';
import '../widgets/handdrawn_components.dart';
import '../widgets/torn_paper_chit.dart';

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
  bool _isDevTestMode = true;

  late final Stream<DocumentSnapshot> _roomStream;
  late final Stream<QuerySnapshot> _playersStream;

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

  List<Map<String, dynamic>> _buildPlayerScoreData(
    List<QueryDocumentSnapshot> players,
    Map<String, dynamic> roomData,
  ) {
    final Map<String, dynamic> roundHistory =
        (roomData['roundHistory'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(roomData['roundHistory'] as Map)
            : {};

    final int currentRound = (roomData['currentRound'] is int)
        ? roomData['currentRound'] as int
        : (roomData['round'] is int)
            ? roomData['round'] as int
            : int.tryParse(
                    roomData['currentRound']?.toString() ??
                        roomData['round']?.toString() ??
                        '1',
                  ) ??
                1;

    final sortedPlayers = List<QueryDocumentSnapshot>.from(players)
      ..sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;
        final scoreA = (dataA['score'] is int)
            ? dataA['score'] as int
            : int.tryParse(dataA['score']?.toString() ?? '0') ?? 0;
        final scoreB = (dataB['score'] is int)
            ? dataB['score'] as int
            : int.tryParse(dataB['score']?.toString() ?? '0') ?? 0;
        return scoreB.compareTo(scoreA);
      });

    return sortedPlayers.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final playerId = doc.id;
      final name = data['name']?.toString() ?? 'Player';
      final overallScore = (data['score'] is int)
          ? data['score'] as int
          : int.tryParse(data['score']?.toString() ?? '0') ?? 0;

      final Map<int, int> roundScoresMap = {};

      roundHistory.forEach((key, val) {
        if (val is Map<String, dynamic>) {
          final roundNum = val['roundNumber'] is int
              ? val['roundNumber'] as int
              : int.tryParse(key.replaceAll('round_', '')) ?? 1;
          final playersList = val['players'] as List<dynamic>? ?? [];
          for (final p in playersList) {
            if (p is Map<String, dynamic> && p['playerId'] == playerId) {
              final rPts = (p['roundScore'] is int)
                  ? p['roundScore'] as int
                  : int.tryParse(p['roundScore']?.toString() ?? '0') ?? 0;
              roundScoresMap[roundNum] = rPts;
            }
          }
        }
      });

      if (!roundScoresMap.containsKey(currentRound)) {
        final currentRoundPts = (data['roundScore'] is int)
            ? data['roundScore'] as int
            : int.tryParse(data['roundScore']?.toString() ?? '0') ?? 0;
        roundScoresMap[currentRound] = currentRoundPts;
      }

      return {
        'playerId': playerId,
        'name': name,
        'roundScores': roundScoresMap,
        'totalPoints': overallScore,
      };
    }).toList();
  }

  void _showScoreboardModal(
    BuildContext context,
    List<QueryDocumentSnapshot> players,
    Map<String, dynamic> roomData,
    int currentRound,
    int roundsTotal,
  ) {
    final playerScores = _buildPlayerScoreData(players, roomData);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF7F4EB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.ballpointBlue, width: 2),
          ),
          contentPadding: const EdgeInsets.all(12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NotebookScoreTable(
                playerScores: playerScores,
                isFinalScore: false,
              ),
              const SizedBox(height: 16),
              HandDrawnButton(
                label: 'CLOSE NOTEBOOK SHEET',
                pencilFillColor: AppColors.pencilBlueFill,
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        );
      },
    );
  }

  void _revealRoleDialog({
    required String playerName,
    required String role,
    required int points,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return SecretRoleRevealDialog(
          playerName: playerName,
          role: role,
          points: points,
        );
      },
    );
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

        if (roomSnapshot.hasError) {
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
                'Room not found.',
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
          (roomData['completedRoles'] as List<dynamic>?)?.map(
                (e) => e.toString(),
              ) ??
              [],
        );
        final Map<String, dynamic>? lastAction =
            roomData['lastAction'] is Map<String, dynamic>
            ? roomData['lastAction'] as Map<String, dynamic>
            : null;
        final String? lastActionMessage = roomData['lastActionMessage']
            ?.toString();

        final int currentRound = (roomData['currentRound'] is int)
            ? roomData['currentRound'] as int
            : (roomData['round'] is int)
            ? roomData['round'] as int
            : int.tryParse(
                    roomData['currentRound']?.toString() ??
                        roomData['round']?.toString() ??
                        '1',
                  ) ??
                  1;

        final int roundsTotal = (roomData['roundsTotal'] is int)
            ? roomData['roundsTotal'] as int
            : int.tryParse(roomData['roundsTotal']?.toString() ?? '3') ?? 3;

        return StreamBuilder<QuerySnapshot>(
          stream: _playersStream,
          builder: (context, playersSnapshot) {
            if (playersSnapshot.connectionState == ConnectionState.waiting &&
                !playersSnapshot.hasData) {
              return const NotebookPaperPage(
                child: RRLoader(message: 'Loading Notebook...'),
              );
            }

            if (playersSnapshot.hasError) {
              return NotebookPaperPage(
                child: Center(
                  child: Text(
                    'Error loading players:\n${playersSnapshot.error}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.patrickHand(color: AppColors.ballpointBlue, fontSize: 18),
                  ),
                ),
              );
            }

            final players = playersSnapshot.data?.docs ?? [];

            if (players.isEmpty) {
              return const NotebookPaperPage(
                child: Center(child: Text('No players found.')),
              );
            }

            final currentUserId = FirebaseAuth.instance.currentUser?.uid;

            // Lock to original logged-in user when DEV mode is OFF
            if (!_isDevTestMode) {
              if (currentUserId != null &&
                  players.any((player) => player.id == currentUserId)) {
                _selectedPlayerId = currentUserId;
              }
            } else {
              if (_selectedPlayerId == null ||
                  !players.any((player) => player.id == _selectedPlayerId)) {
                if (currentUserId != null &&
                    players.any((player) => player.id == currentUserId)) {
                  _selectedPlayerId = currentUserId;
                } else {
                  _selectedPlayerId = players.first.id;
                }
              }
            }

            if (status == 'roleSelection') {
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

            return NotebookPaperPage(
              child: Column(
                children: [
                  // Notebook Header with Badges & Scoreboard Button
                  NotebookHeader(
                    currentRound: currentRound,
                    totalRounds: roundsTotal,
                    isDevMode: _isDevTestMode,
                    onScoreboardTap: () => _showScoreboardModal(
                      context,
                      players,
                      roomData,
                      currentRound,
                      roundsTotal,
                    ),
                    onDevToggle: () {
                      setState(() {
                        _isDevTestMode = !_isDevTestMode;
                        if (!_isDevTestMode && currentUserId != null) {
                          if (players.any((p) => p.id == currentUserId)) {
                            _selectedPlayerId = currentUserId;
                          }
                        }
                      });
                    },
                  ),

                  Builder(
                    builder: (context) {
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

                      final selectedPlayerDoc = players.firstWhere(
                        (player) => player.id == _selectedPlayerId,
                      );

                      final selectedData =
                          selectedPlayerDoc.data() as Map<String, dynamic>;
                      final selectedName =
                          selectedData['name']?.toString() ?? 'Player';
                      final selectedRole =
                          selectedData['role']?.toString() ?? '';
                      final selectedPoints =
                          (selectedData['rolePoints'] is int)
                          ? selectedData['rolePoints'] as int
                          : int.tryParse(
                                  selectedData['rolePoints']?.toString() ??
                                      '0',
                                ) ??
                                0;
                      final selectedRoundScore =
                          (selectedData['roundScore'] is int)
                          ? selectedData['roundScore'] as int
                          : int.tryParse(
                                  selectedData['roundScore']?.toString() ??
                                      '0',
                                ) ??
                                0;
                      final selectedScore = (selectedData['score'] is int)
                          ? selectedData['score'] as int
                          : int.tryParse(
                                  selectedData['score']?.toString() ?? '0',
                                ) ??
                                0;

                      final isMyTurn =
                          selectedPlayerDoc.id == currentTurnPlayerId;
                      final currentTurnPlayerName = _getPlayerName(
                        players,
                        currentTurnPlayerId,
                      );

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
                ],
              ),
            );
          },
        );
      },
    );
  }

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
    return Column(
      children: [
        // DEV TEST MODE PLAYER SWITCHER TOOLBAR
        if (_isDevTestMode) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.redInk, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEV TEST MODE — SWITCH ACTIVE PLAYER VIEW',
                  style: GoogleFonts.kalam(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: AppColors.redInk,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: selectedPlayerId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    filled: false,
                  ),
                  items: players.map((p) {
                    final data = p.data() as Map<String, dynamic>;
                    final pName = data['name']?.toString() ?? 'Player';
                    final pRole = data['role']?.toString() ?? 'No role';
                    final bool isTurn = p.id == currentTurnPlayerId;

                    return DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(
                        '$pName ($pRole)${isTurn ? ' — TURN' : ''}',
                        style: GoogleFonts.patrickHand(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isTurn ? AppColors.redInk : AppColors.ballpointBlue,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPlayerId = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],

        // 1. Interactive Folded Paper Chit Placed Toward Top Area
        GestureDetector(
          onTap: () {
            if (selectedRole.isNotEmpty) {
              _revealRoleDialog(
                playerName: selectedPlayerName,
                role: selectedRole,
                points: selectedPoints,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                TornPaperChit(
                  label: 'MY CHIT',
                  role: selectedRole,
                  points: selectedPoints,
                  isFolded: true,
                  isSelected: true,
                  width: 130,
                  height: 155,
                  onTap: () {
                    if (selectedRole.isNotEmpty) {
                      _revealRoleDialog(
                        playerName: selectedPlayerName,
                        role: selectedRole,
                        points: selectedPoints,
                      );
                    }
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.touch_app, size: 16, color: AppColors.ballpointBlue),
                    const SizedBox(width: 4),
                    Text(
                      'Tap paper chit to unfold & view secret role!',
                      style: GoogleFonts.caveat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ballpointBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 2. TURN SECTION BELOW THE CHIT
        Column(
          children: [
            Text(
              isMyTurn
                  ? 'ITS YOUR TURN!'
                  : '$currentTurnPlayerName\'s Turn to find $currentTargetRole!',
              textAlign: TextAlign.center,
              style: GoogleFonts.kalam(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isMyTurn ? AppColors.redInk : AppColors.ballpointBlue,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            HandDrawnUnderline(
              width: isMyTurn ? 170 : 220,
              isDouble: isMyTurn,
              color: isMyTurn ? AppColors.redInk : AppColors.ballpointBlue,
            ),
            if (!isMyTurn) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.pencilYellowFill.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.ballpointBlue, width: 1.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_top_rounded, color: AppColors.redInk, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'WAIT FOR OTHER PLAYERS\' GUESS...',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.kalam(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.redInk,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 20),

        // 3. GUESSING PLAYERS LIST IN 2-COLUMN GRID (p1 p2 / p3 p4 / p5 p6)
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'SELECT PLAYER TO GUESS:',
            style: GoogleFonts.kalam(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ballpointBlue,
              letterSpacing: 1.0,
            ),
          ),
        ),

        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.75,
          ),
          itemCount: players.length,
          itemBuilder: (context, index) {
            final playerDoc = players[index];
            final pData = playerDoc.data() as Map<String, dynamic>;
            final pId = playerDoc.id;
            final pName = pData['name']?.toString() ?? 'Player';
            final pRole = pData['role']?.toString() ?? '';
            final isSelf = pId == selectedPlayerId;

            final bool isCompleted = pRole.isNotEmpty &&
                completedRoles
                    .map((r) => r.toLowerCase())
                    .contains(pRole.toLowerCase());

            final canGuess = isMyTurn && !isSelf && !isCompleted && !_isProcessingGuess;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: isSelf
                    ? AppColors.pencilBlueFill.withValues(alpha: 0.35)
                    : isCompleted
                        ? AppColors.pencilGreenFill.withValues(alpha: 0.25)
                        : const Color(0xFFFFFDF8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelf
                      ? AppColors.ballpointBlue
                      : isCompleted
                          ? AppColors.penGreen
                          : AppColors.blueRuling,
                  width: 1.4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isCompleted ? '✓ ' : '○ ',
                        style: GoogleFonts.kalam(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? AppColors.penGreen : AppColors.ballpointBlue,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          pName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.patrickHand(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? AppColors.penGreen : AppColors.ballpointBlue,
                          ),
                        ),
                      ),
                      if (isSelf) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(YOU)',
                          style: GoogleFonts.kalam(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.redInk,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.pencilGreenFill.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.penGreen, width: 1.0),
                      ),
                      child: Text(
                        'COMPLETED ($pRole)',
                        style: GoogleFonts.kalam(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.penGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  else if (canGuess)
                    HandDrawnButton(
                      label: 'GUESS',
                      pencilFillColor: AppColors.pencilGreenFill,
                      onPressed: () => _handleGuess(
                        selectedPlayerId,
                        selectedPlayerName,
                        pId,
                        pName,
                        currentRole,
                        currentTargetRole,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _handleGuess(
    String guesserId,
    String guesserName,
    String targetId,
    String targetName,
    String currentRole,
    String currentTargetRole,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isProcessingGuess = true;
    });

    try {
      final result = await _roomService.makeGuess(
        roomId: widget.roomId,
        guessingPlayerId: guesserId,
        targetPlayerId: targetId,
      );

      final bool isCorrect = result['isCorrect'] == true;
      final String message = result['message']?.toString() ?? '';

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return GuessResultDialog(
              isCorrect: isCorrect,
              guesserName: guesserName,
              targetName: targetName,
              targetRole: currentTargetRole,
              message: message,
              onClose: () => Navigator.pop(dialogContext),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to submit guess: $e'),
            backgroundColor: AppColors.terracotta,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingGuess = false;
        });
      }
    }
  }

  String _getPlayerName(List<QueryDocumentSnapshot> players, String id) {
    for (final p in players) {
      if (p.id == id) {
        final data = p.data() as Map<String, dynamic>;
        return data['name']?.toString() ?? 'Player';
      }
    }
    return 'Player';
  }

  Widget _buildRoundResultScreen(
    BuildContext context,
    List<QueryDocumentSnapshot> players,
    Map<String, dynamic> roomData,
    int currentRound,
    int roundsTotal,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isHost = players.isNotEmpty && players.first.id == currentUser?.uid;
    final playerScores = _buildPlayerScoreData(players, roomData);

    return Column(
      children: [
        NotebookResultCard(
          title: 'ROUND $currentRound COMPLETE',
          subtitle: 'Scores written in notebook sheet:',
          icon: Icons.assignment_turned_in,
        ),
        const SizedBox(height: 20),
        NotebookScoreTable(
          playerScores: playerScores,
          isFinalScore: false,
        ),
        const SizedBox(height: 24),
        if (isHost || _isDevTestMode)
          HandDrawnButton(
            label: 'START ROUND ${currentRound + 1}',
            pencilFillColor: AppColors.pencilGreenFill,
            onPressed: () async {
              try {
                await _roomService.startNextRound(roomId: widget.roomId);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to start next round: $e')),
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildFinalScoreboardScreen(
    BuildContext context,
    List<QueryDocumentSnapshot> playersSnapshotDocs,
    Map<String, dynamic> roomData,
    int roundsTotal,
  ) {
    final playerScores = _buildPlayerScoreData(playersSnapshotDocs, roomData);

    return Column(
      children: [
        const NotebookResultCard(
          title: '★ GOOD GAME!',
          subtitle: 'Here is the final score card:',
          icon: Icons.star,
        ),

        const SizedBox(height: 20),

        NotebookScoreTable(
          playerScores: playerScores,
          isFinalScore: true,
        ),

        const SizedBox(height: 28),

        HandDrawnButton(
          label: 'BACK TO LOBBY',
          pencilFillColor: AppColors.pencilBlueFill,
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
