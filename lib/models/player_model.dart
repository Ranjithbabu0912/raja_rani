import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerModel {
  final String playerId;
  final String name;
  final String role;
  final int rolePoints;
  final int score;
  final int roundScore;
  final bool isReady;
  final int? selectedCardIndex;
  final DateTime? joinedAt;
  final bool isConnected;

  PlayerModel({
    required this.playerId,
    required this.name,
    required this.role,
    required this.rolePoints,
    required this.score,
    required this.roundScore,
    required this.isReady,
    this.selectedCardIndex,
    this.joinedAt,
    required this.isConnected,
  });

  factory PlayerModel.fromMap(String id, Map<String, dynamic> map) {
    final parsedCardIndex = (map['selectedCardIndex'] is int)
        ? map['selectedCardIndex'] as int
        : int.tryParse(map['selectedCardIndex']?.toString() ?? '');

    return PlayerModel(
      playerId: id,
      name: map['name']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      rolePoints: (map['rolePoints'] is int)
          ? map['rolePoints'] as int
          : int.tryParse(map['rolePoints']?.toString() ?? '0') ?? 0,
      score: (map['score'] is int)
          ? map['score'] as int
          : int.tryParse(map['score']?.toString() ?? '0') ?? 0,
      roundScore: (map['roundScore'] is int)
          ? map['roundScore'] as int
          : int.tryParse(map['roundScore']?.toString() ?? '0') ?? 0,
      isReady: map['isReady'] == true,
      selectedCardIndex: parsedCardIndex,
      joinedAt: map['joinedAt'] is Timestamp
          ? (map['joinedAt'] as Timestamp).toDate()
          : null,
      isConnected: map['isConnected'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'rolePoints': rolePoints,
      'score': score,
      'roundScore': roundScore,
      'isReady': isReady,
      'selectedCardIndex': selectedCardIndex,
      'joinedAt': joinedAt,
      'isConnected': isConnected,
    };
  }
}
