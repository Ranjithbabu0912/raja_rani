import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String roomId;
  final String hostId;
  final String status;
  final String currentTurnPlayerId;
  final String currentRajaId;
  final String currentRole;
  final String currentTargetRole;
  final List<String> completedRoles;
  final int round;
  final int currentRound;
  final int roundsTotal;
  final Map<String, dynamic>? lastAction;
  final String? lastActionMessage;
  final DateTime? createdAt;

  RoomModel({
    required this.roomId,
    required this.hostId,
    required this.status,
    required this.currentTurnPlayerId,
    required this.currentRajaId,
    required this.currentRole,
    required this.currentTargetRole,
    required this.completedRoles,
    required this.round,
    required this.currentRound,
    required this.roundsTotal,
    this.lastAction,
    this.lastActionMessage,
    this.createdAt,
  });

  factory RoomModel.fromMap(String id, Map<String, dynamic> map) {
    final parsedCurrentRound = (map['currentRound'] is int)
        ? map['currentRound'] as int
        : (map['round'] is int)
            ? map['round'] as int
            : int.tryParse(map['currentRound']?.toString() ?? map['round']?.toString() ?? '1') ?? 1;

    final parsedRoundsTotal = (map['roundsTotal'] is int)
        ? map['roundsTotal'] as int
        : int.tryParse(map['roundsTotal']?.toString() ?? '3') ?? 3;

    return RoomModel(
      roomId: id,
      hostId: map['hostId']?.toString() ?? '',
      status: map['status']?.toString() ?? 'waiting',
      currentTurnPlayerId: map['currentTurnPlayerId']?.toString() ??
          map['currentTurn']?.toString() ??
          map['currentRajaId']?.toString() ??
          '',
      currentRajaId: map['currentRajaId']?.toString() ?? '',
      currentRole: map['currentRole']?.toString() ?? '',
      currentTargetRole: map['currentTargetRole']?.toString() ?? '',
      completedRoles: List<String>.from(
        (map['completedRoles'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      ),
      round: parsedCurrentRound,
      currentRound: parsedCurrentRound,
      roundsTotal: parsedRoundsTotal,
      lastAction: map['lastAction'] is Map<String, dynamic>
          ? map['lastAction'] as Map<String, dynamic>
          : null,
      lastActionMessage: map['lastActionMessage']?.toString(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'status': status,
      'currentTurnPlayerId': currentTurnPlayerId,
      'currentRajaId': currentRajaId,
      'currentRole': currentRole,
      'currentTargetRole': currentTargetRole,
      'completedRoles': completedRoles,
      'round': currentRound,
      'currentRound': currentRound,
      'roundsTotal': roundsTotal,
      'lastAction': lastAction,
      'lastActionMessage': lastActionMessage,
      'createdAt': createdAt,
    };
  }
}
