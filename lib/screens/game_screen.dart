import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/room_service.dart';

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
        return Colors.amber.shade700;
      case 'rani':
        return Colors.pink.shade400;
      case 'manthiri':
        return Colors.purple.shade400;
      case 'sippai':
        return Colors.blue.shade600;
      case 'police':
        return Colors.indigo.shade600;
      case 'thirudan':
        return Colors.deepOrange.shade600;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raja Rani Game'),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade800,
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
                    final currentUid = FirebaseAuth.instance.currentUser?.uid;
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
            return const Center(child: Text('Room not found.'));
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

          return StreamBuilder<QuerySnapshot>(
            stream: roomRef
                .collection('players')
                .orderBy('joinedAt')
                .snapshots(),
            builder: (context, playersSnapshot) {
              if (playersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
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

              if (status == 'completed') {
                return _buildCompletedScreen(context, players, roomData);
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
                );
              }

              return _buildActiveGame(
                context: context,
                players: players,
                selectedPlayerId: selectedPlayerDoc.id,
                selectedPlayerName: selectedName,
                selectedRole: selectedRole,
                selectedPoints: selectedPoints,
                selectedScore: selectedScore,
                isMyTurn: isMyTurn,
                currentTurnPlayerId: currentTurnPlayerId,
                currentTurnPlayerName: currentTurnPlayerName,
                currentRole: currentRole,
                currentTargetRole: currentTargetRole,
                completedRoles: completedRoles,
                lastAction: lastAction,
                lastActionMessage: lastActionMessage,
              );
            },
          );
        },
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
                          const Text(
                            'ALL 6 PLAYERS TEST DASHBOARD',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.black87,
                            ),
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
                                  'Role: ${role.toUpperCase()} ($rolePoints pts) | Score: $score pts',
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
    required int selectedScore,
    required bool isMyTurn,
    required String currentTurnPlayerId,
    required String currentTurnPlayerName,
    required String currentRole,
    required String currentTargetRole,
    required List<String> completedRoles,
    required Map<String, dynamic>? lastAction,
    required String? lastActionMessage,
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
                              'Earned Score',
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

  Widget _buildCompletedScreen(
    BuildContext context,
    List<QueryDocumentSnapshot> players,
    Map<String, dynamic> roomData,
  ) {
    // Sort players by score descending
    final sortedPlayers = List<QueryDocumentSnapshot>.from(players)
      ..sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aScore = (aData['score'] is int)
            ? aData['score'] as int
            : int.tryParse(aData['score']?.toString() ?? '0') ?? 0;
        final bScore = (bData['score'] is int)
            ? bData['score'] as int
            : int.tryParse(bData['score']?.toString() ?? '0') ?? 0;
        return bScore.compareTo(aScore);
      });

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 12),
            const Text(
              'GAME COMPLETED!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'All roles have been identified. Final Scoreboard:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'FINAL RANKINGS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Divider(height: 24),
                    ...sortedPlayers.asMap().entries.map((entry) {
                      final rank = entry.key + 1;
                      final player = entry.value;
                      final data = player.data() as Map<String, dynamic>;
                      final name = data['name']?.toString() ?? 'Player';
                      final role = data['role']?.toString() ?? 'Role';
                      final score = (data['score'] is int)
                          ? data['score'] as int
                          : int.tryParse(data['score']?.toString() ?? '0') ?? 0;

                      String medal = '';
                      if (rank == 1) medal = '🥇 ';
                      if (rank == 2) medal = '🥈 ';
                      if (rank == 3) medal = '🥉 ';

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: rank == 1
                              ? Colors.amber.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: rank == 1
                              ? Border.all(color: Colors.amber.shade600)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$medal#$rank',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Final Role: ${role.toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$score pts',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
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
