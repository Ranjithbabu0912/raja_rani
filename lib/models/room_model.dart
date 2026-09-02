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
    this.lastAction,
    this.lastActionMessage,
    this.createdAt,
  });

  factory RoomModel.fromMap(String id, Map<String, dynamic> map) {
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
      round: (map['round'] is int)
          ? map['round'] as int
          : int.tryParse(map['round']?.toString() ?? '0') ?? 0,
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
      'round': round,
      'lastAction': lastAction,
      'lastActionMessage': lastActionMessage,
      'createdAt': createdAt,
    };
  }
}
