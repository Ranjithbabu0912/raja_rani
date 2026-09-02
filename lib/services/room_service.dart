import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/game_role.dart';
import 'role_service.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createRoom({required String playerName}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Player is not authenticated.');
    }

    final roomId = _generateRoomId();

    final roomRef = _firestore.collection('rooms').doc(roomId);

    await roomRef.set({
      'hostId': user.uid,
      'status': 'waiting',
      'currentTurnPlayerId': '',
      'currentRajaId': '',
      'currentRole': '',
      'currentTargetRole': '',
      'completedRoles': [],
      'round': 0,
      'createdAt': Timestamp.now(),
    });

    await roomRef.collection('players').doc(user.uid).set({
      'name': playerName,
      'role': '',
      'rolePoints': 0,
      'score': 0,
      'isReady': false,
      'joinedAt': Timestamp.now(),
      'isConnected': true,
    });

    return roomId;
  }

  Future<void> joinRoom({
    required String roomId,
    required String playerName,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Player is not authenticated.');
    }

    final roomRef = _firestore.collection('rooms').doc(roomId);

    final roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      throw Exception('Room not found.');
    }

    final playerRef = roomRef.collection('players').doc(user.uid);

    final existingPlayer = await playerRef.get();

    if (existingPlayer.exists) {
      throw Exception('You are already in this room.');
    }

    final playersSnapshot = await roomRef.collection('players').get();

    if (playersSnapshot.docs.length >= 6) {
      throw Exception('Room is full. Maximum 6 players.');
    }

    await playerRef.set({
      'name': playerName,
      'role': '',
      'rolePoints': 0,
      'score': 0,
      'isReady': false,
      'joinedAt': Timestamp.now(),
      'isConnected': true,
    });
  }

  Future<void> toggleReady({
    required String roomId,
    required bool isReady,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Player is not authenticated.');
    }

    final playerRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('players')
        .doc(user.uid);

    await playerRef.update({'isReady': isReady});
  }

  Future<void> addSamplePlayers({required String roomId}) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);

    final samplePlayers = [
      {'id': 'sample_arun', 'name': 'Arun'},
      {'id': 'sample_kumar', 'name': 'Kumar'},
      {'id': 'sample_suresh', 'name': 'Suresh'},
      {'id': 'sample_vijay', 'name': 'Vijay'},
      {'id': 'sample_praveen', 'name': 'Praveen'},
    ];

    for (final player in samplePlayers) {
      await roomRef.collection('players').doc(player['id']).set({
        'name': player['name'],
        'role': '',
        'rolePoints': 0,
        'score': 0,
        'isReady': true,
        'joinedAt': Timestamp.now(),
        'isConnected': true,
      });
    }
  }

  String _generateRoomId() {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();

    return List.generate(
      6,
      (_) => characters[random.nextInt(characters.length)],
    ).join();
  }

  Future<void> startGame({required String roomId}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Player is not authenticated.');
    }

    final roomRef = _firestore.collection('rooms').doc(roomId);

    // Get all players
    final playersSnapshot = await roomRef
        .collection('players')
        .orderBy('joinedAt')
        .get();

    final players = playersSnapshot.docs;

    // Requires exactly 6 players
    if (players.length != 6) {
      throw Exception('The game requires exactly 6 players.');
    }

    // Make sure current player is the host
    if (players.first.id != user.uid) {
      throw Exception('Only the host can start the game.');
    }

    // Make sure everybody is ready
    final allReady = players.every((player) {
      final data = player.data();

      return data['isReady'] == true;
    });

    if (!allReady) {
      throw Exception('All players must be ready.');
    }

    // Generate random roles for all 6 players
    final roles = RoleService.generateRandomRoles();

    final batch = _firestore.batch();
    String rajaPlayerId = '';

    for (int i = 0; i < players.length; i++) {
      final playerRef = players[i].reference;
      final role = roles[i];

      if (role == GameRole.raja) {
        rajaPlayerId = players[i].id;
      }

      batch.update(playerRef, {
        'role': role.displayName,
        'rolePoints': role.points,
        'score': 0,
      });
    }

    final timestamp = FieldValue.serverTimestamp();

    // Start the game with Raja seeking Rani
    batch.update(roomRef, {
      'status': 'playing',
      'currentTurnPlayerId': rajaPlayerId,
      'currentRajaId': rajaPlayerId,
      'currentRole': GameRole.raja.displayName,
      'currentTargetRole': GameRole.rani.displayName,
      'completedRoles': [],
      'round': 1,
      'gameStartedAt': timestamp,
      'lastActionMessage': 'Game started! Raja must find Rani.',
      'lastActionTimestamp': timestamp,
      'lastAction': {
        'type': 'game_start',
        'message': 'Game started! Raja must find Rani.',
        'timestamp': timestamp,
      },
    });

    await batch.commit();
  }

  Future<Map<String, dynamic>> makeGuess({
    required String roomId,
    required String guessingPlayerId,
    required String targetPlayerId,
  }) async {
    if (guessingPlayerId == targetPlayerId) {
      throw Exception('A player cannot guess themselves.');
    }

    final roomRef = _firestore.collection('rooms').doc(roomId);
    final guessingPlayerRef =
        roomRef.collection('players').doc(guessingPlayerId);
    final targetPlayerRef =
        roomRef.collection('players').doc(targetPlayerId);

    return await _firestore
        .runTransaction<Map<String, dynamic>>((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) {
        throw Exception('Room does not exist.');
      }

      final roomData = roomSnapshot.data() as Map<String, dynamic>;
      if (roomData['status'] != 'playing') {
        throw Exception('Game is not currently playing.');
      }

      final String currentTurnPlayerId =
          roomData['currentTurnPlayerId']?.toString() ??
          roomData['currentRajaId']?.toString() ??
          '';

      if (currentTurnPlayerId != guessingPlayerId) {
        throw Exception('It is not this player\'s turn to guess.');
      }

      final guessingPlayerSnapshot = await transaction.get(guessingPlayerRef);
      final targetPlayerSnapshot = await transaction.get(targetPlayerRef);

      if (!guessingPlayerSnapshot.exists || !targetPlayerSnapshot.exists) {
        throw Exception('Player records not found in room.');
      }

      final guessingData =
          guessingPlayerSnapshot.data() as Map<String, dynamic>;
      final targetData = targetPlayerSnapshot.data() as Map<String, dynamic>;

      final List<String> completedRoles = List<String>.from(
        (roomData['completedRoles'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      );

      final String targetActualRole = targetData['role']?.toString() ?? '';

      // Validate that target player's role has not already completed their turn
      if (completedRoles
          .map((r) => r.toLowerCase())
          .contains(targetActualRole.toLowerCase())) {
        throw Exception(
          'This player ($targetActualRole) has already completed their turn and cannot be guessed.',
        );
      }

      final String guessingPlayerName =
          guessingData['name']?.toString() ?? 'Player';
      final String targetPlayerName =
          targetData['name']?.toString() ?? 'Player';

      final String currentRoleStr =
          roomData['currentRole']?.toString() ??
          guessingData['role']?.toString() ??
          'Raja';
      final String currentTargetRoleStr =
          roomData['currentTargetRole']?.toString() ?? 'Rani';

      final bool isCorrect =
          targetActualRole.toLowerCase() == currentTargetRoleStr.toLowerCase();

      final timestamp = FieldValue.serverTimestamp();

      if (isCorrect) {
        final int earnedPoints = _getPointsForRoleName(currentRoleStr);

        final int oldScore = (guessingData['score'] is int)
            ? guessingData['score'] as int
            : int.tryParse(guessingData['score']?.toString() ?? '0') ?? 0;

        final int newScore = oldScore + earnedPoints;

        // Update guessing player score
        transaction.update(guessingPlayerRef, {'score': newScore});

        // Add currentRoleStr to completedRoles as this guessing role successfully completed its guess
        final updatedCompletedRoles = List<String>.from(completedRoles);
        if (!updatedCompletedRoles
            .map((r) => r.toLowerCase())
            .contains(currentRoleStr.toLowerCase())) {
          updatedCompletedRoles.add(currentRoleStr);
        }

        final String? nextTargetRole = _getNextTargetRole(currentTargetRoleStr);
        final String nextRole = currentTargetRoleStr;

        if (nextTargetRole == null) {
          // Game Completed (Police found Thirudan)
          if (!updatedCompletedRoles
              .map((r) => r.toLowerCase())
              .contains(currentTargetRoleStr.toLowerCase())) {
            updatedCompletedRoles.add(currentTargetRoleStr);
          }

          final lastAction = {
            'type': 'guess_result',
            'result': 'correct',
            'guessingPlayerId': guessingPlayerId,
            'guessingPlayerName': guessingPlayerName,
            'selectedPlayerId': targetPlayerId,
            'selectedPlayerName': targetPlayerName,
            'guessingRole': currentRoleStr,
            'targetRole': currentTargetRoleStr,
            'message':
                '$guessingPlayerName ($currentRoleStr) correctly guessed $targetPlayerName as $currentTargetRoleStr! Game Completed!',
            'timestamp': timestamp,
          };

          transaction.update(roomRef, {
            'status': 'completed',
            'completedRoles': updatedCompletedRoles,
            'lastAction': lastAction,
            'lastActionMessage':
                '$guessingPlayerName ($currentRoleStr) guessed $targetPlayerName ($currentTargetRoleStr) — CORRECT! Game Completed!',
            'lastActionTimestamp': timestamp,
            'gameCompletedAt': timestamp,
          });

          return {
            'isCorrect': true,
            'isGameCompleted': true,
            'message':
                '$guessingPlayerName correctly guessed $targetPlayerName! Game Completed!',
          };
        } else {
          // Next round transition
          final lastAction = {
            'type': 'guess_result',
            'result': 'correct',
            'guessingPlayerId': guessingPlayerId,
            'guessingPlayerName': guessingPlayerName,
            'selectedPlayerId': targetPlayerId,
            'selectedPlayerName': targetPlayerName,
            'guessingRole': currentRoleStr,
            'targetRole': currentTargetRoleStr,
            'message':
                '$guessingPlayerName ($currentRoleStr) correctly guessed $targetPlayerName as $currentTargetRoleStr! +$earnedPoints pts.',
            'timestamp': timestamp,
          };

          final Map<String, dynamic> roomUpdates = {
            'currentTurnPlayerId': targetPlayerId,
            'currentRole': nextRole,
            'currentTargetRole': nextTargetRole,
            'completedRoles': updatedCompletedRoles,
            'lastAction': lastAction,
            'lastActionMessage':
                '$guessingPlayerName ($currentRoleStr) guessed $targetPlayerName ($currentTargetRoleStr) — CORRECT! Next: $nextRole finds $nextTargetRole.',
            'lastActionTimestamp': timestamp,
          };

          if (nextRole.toLowerCase() == 'raja') {
            roomUpdates['currentRajaId'] = targetPlayerId;
          }

          transaction.update(roomRef, roomUpdates);

          return {
            'isCorrect': true,
            'isGameCompleted': false,
            'message':
                '$guessingPlayerName correctly guessed $targetPlayerName!',
          };
        }
      } else {
        // Wrong Guess: Exchange roles and rolePoints
        final guessingRole = guessingData['role'];
        final guessingRolePoints = guessingData['rolePoints'];
        final targetRole = targetData['role'];
        final targetRolePoints = targetData['rolePoints'];

        transaction.update(guessingPlayerRef, {
          'role': targetRole,
          'rolePoints': targetRolePoints,
        });

        transaction.update(targetPlayerRef, {
          'role': guessingRole,
          'rolePoints': guessingRolePoints,
        });

        final String newCurrentTurnPlayerId = targetPlayerId;

        final lastAction = {
          'type': 'guess_result',
          'result': 'wrong',
          'guessingPlayerId': guessingPlayerId,
          'guessingPlayerName': guessingPlayerName,
          'selectedPlayerId': targetPlayerId,
          'selectedPlayerName': targetPlayerName,
          'guessingRole': currentRoleStr,
          'targetRole': currentTargetRoleStr,
          'message':
              '$guessingPlayerName ($currentRoleStr) guessed $targetPlayerName — WRONG! Roles exchanged. $targetPlayerName is now $currentRoleStr.',
          'timestamp': timestamp,
        };

        final Map<String, dynamic> roomUpdates = {
          'currentTurnPlayerId': newCurrentTurnPlayerId,
          'lastAction': lastAction,
          'lastActionMessage':
              '$guessingPlayerName ($currentRoleStr) guessed $targetPlayerName — WRONG! Roles exchanged.',
          'lastActionTimestamp': timestamp,
        };

        if (currentRoleStr.toLowerCase() == 'raja') {
          roomUpdates['currentRajaId'] = newCurrentTurnPlayerId;
        }

        transaction.update(roomRef, roomUpdates);

        return {
          'isCorrect': false,
          'isGameCompleted': false,
          'message':
              '$guessingPlayerName guessed $targetPlayerName — WRONG! Roles exchanged.',
        };
      }
    });
  }

  String? _getNextTargetRole(String currentTargetRole) {
    switch (currentTargetRole.toLowerCase()) {
      case 'rani':
        return 'Manthiri';
      case 'manthiri':
        return 'Sippai';
      case 'sippai':
        return 'Police';
      case 'police':
        return 'Thirudan';
      case 'thirudan':
        return null;
      default:
        return null;
    }
  }

  int _getPointsForRoleName(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'raja':
        return 5000;
      case 'rani':
        return 3000;
      case 'manthiri':
        return 2000;
      case 'sippai':
        return 1000;
      case 'police':
        return 500;
      case 'thirudan':
        return 0;
      default:
        return 0;
    }
  }

  Future<bool> checkRaniGuess({
    required String roomId,
    required String selectedPlayerId,
  }) async {
    final selectedPlayerRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('players')
        .doc(selectedPlayerId);

    final selectedPlayer = await selectedPlayerRef.get();

    if (!selectedPlayer.exists) {
      throw Exception('Selected player does not exist.');
    }

    final data = selectedPlayer.data();

    if (data == null) {
      throw Exception('Player data not found.');
    }

    final role = data['role'] ?? '';

    return role.toString().toLowerCase() == 'rani';
  }

  Future<void> exchangeRolesAfterWrongGuess({
    required String roomId,
    required String rajaPlayerId,
    required String guessedPlayerId,
  }) async {
    await makeGuess(
      roomId: roomId,
      guessingPlayerId: rajaPlayerId,
      targetPlayerId: guessedPlayerId,
    );
  }
}
