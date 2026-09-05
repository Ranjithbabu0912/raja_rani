import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/room_service.dart';
import '../utils/app_theme.dart';
import '../widgets/handdrawn_components.dart';
import '../widgets/torn_paper_chit.dart';

class CardSelectionWidget extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> roomData;
  final List<QueryDocumentSnapshot> players;
  final String activePlayerId;
  final ValueChanged<String>? onPlayerSwitched;
  final bool isDevTestMode;

  const CardSelectionWidget({
    super.key,
    required this.roomId,
    required this.roomData,
    required this.players,
    required this.activePlayerId,
    this.onPlayerSwitched,
    this.isDevTestMode = false,
  });

  @override
  State<CardSelectionWidget> createState() => _CardSelectionWidgetState();
}

class _CardSelectionWidgetState extends State<CardSelectionWidget>
    with SingleTickerProviderStateMixin {
  final RoomService _roomService = RoomService();
  bool _isSelecting = false;

  // Animation controller for physical paper shuffle animation
  late AnimationController _shuffleController;

  // Pre-calculated physical rotation angles for the 6 paper chits
  final List<double> _paperAngles = [-0.08, 0.05, -0.03, 0.07, -0.05, 0.04];

  @override
  void initState() {
    super.initState();
    _shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _shuffleController.forward();
  }

  @override
  void dispose() {
    _shuffleController.dispose();
    super.dispose();
  }

  void _showSecretRoleDialog({
    required String playerName,
    required String role,
    required int points,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _SecretRoleRevealDialog(
          playerName: playerName,
          role: role,
          points: points,
        );
      },
    );
  }

  Future<void> _handlePaperTap(
    int cardIndex,
    String activePlayerId,
    String activePlayerName,
  ) async {
    final Map<String, dynamic> cardSelections =
        (widget.roomData['cardSelections'] is Map<String, dynamic>)
        ? widget.roomData['cardSelections'] as Map<String, dynamic>
        : {};

    final String cardKey = '$cardIndex';
    final selection = cardSelections[cardKey];

    // Case 1: Paper already taken
    if (selection != null) {
      final selectedBy = selection['playerId']?.toString() ?? '';
      final selectedByName =
          selection['playerName']?.toString() ?? 'Another player';

      if (selectedBy == activePlayerId) {
        _revealPlayerRole(activePlayerId, activePlayerName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This paper chit was taken by $selectedByName.'),
            backgroundColor: AppColors.terracotta,
          ),
        );
      }
      return;
    }

    // Case 2: Active player has already picked another paper
    bool hasSelectedAnotherCard = false;
    int previousCardIndex = -1;
    cardSelections.forEach((key, value) {
      if (value is Map<String, dynamic> &&
          value['playerId'] == activePlayerId) {
        hasSelectedAnotherCard = true;
        previousCardIndex = int.tryParse(key) ?? -1;
      }
    });

    if (hasSelectedAnotherCard) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You already took Paper #$previousCardIndex. Everyone gets one paper!',
          ),
          backgroundColor: AppColors.terracotta,
        ),
      );
      return;
    }

    // Case 3: Pick Paper Chit
    setState(() {
      _isSelecting = true;
    });

    try {
      await _roomService.selectRoleCard(
        roomId: widget.roomId,
        playerId: activePlayerId,
        cardIndex: cardIndex,
      );

      if (mounted) {
        _revealPlayerRole(activePlayerId, activePlayerName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.terracotta,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSelecting = false;
        });
      }
    }
  }

  void _revealPlayerRole(String playerId, String playerName) {
    QueryDocumentSnapshot? playerDoc;
    for (final p in widget.players) {
      if (p.id == playerId) {
        playerDoc = p;
        break;
      }
    }
    if (playerDoc == null && widget.players.isNotEmpty) {
      playerDoc = widget.players.first;
    }
    if (playerDoc == null) return;

    final playerData = playerDoc.data() as Map<String, dynamic>;
    final role = playerData['role']?.toString() ?? '';
    final points = (playerData['rolePoints'] is int)
        ? playerData['rolePoints'] as int
        : int.tryParse(playerData['rolePoints']?.toString() ?? '0') ?? 0;

    if (role.isEmpty) return;

    _showSecretRoleDialog(playerName: playerName, role: role, points: points);
  }

  @override
  Widget build(BuildContext context) {
    final int currentRound = (widget.roomData['currentRound'] is int)
        ? widget.roomData['currentRound'] as int
        : int.tryParse(widget.roomData['currentRound']?.toString() ?? '1') ?? 1;

    final int roundsTotal = (widget.roomData['roundsTotal'] is int)
        ? widget.roomData['roundsTotal'] as int
        : int.tryParse(widget.roomData['roundsTotal']?.toString() ?? '3') ?? 3;

    final Map<String, dynamic> cardSelections =
        (widget.roomData['cardSelections'] is Map<String, dynamic>)
        ? widget.roomData['cardSelections'] as Map<String, dynamic>
        : {};

    final int selectedCount = cardSelections.length;

    QueryDocumentSnapshot? activePlayerDoc;
    for (final p in widget.players) {
      if (p.id == widget.activePlayerId) {
        activePlayerDoc = p;
        break;
      }
    }
    if (activePlayerDoc == null && widget.players.isNotEmpty) {
      activePlayerDoc = widget.players.first;
    }

    final activePlayerData =
        activePlayerDoc?.data() as Map<String, dynamic>? ?? {};
    final activePlayerName = activePlayerData['name']?.toString() ?? 'Player';

    int? activePlayerCardIndex;
    cardSelections.forEach((key, value) {
      if (value is Map<String, dynamic> &&
          value['playerId'] == widget.activePlayerId) {
        activePlayerCardIndex = int.tryParse(key);
      }
    });

    final bool activePlayerHasRole =
        (activePlayerData['role']?.toString() ?? '').isNotEmpty;

    return NotebookPaperPage(
      child: Column(
        children: [
          // Notebook Header Bar
          NotebookHeader(
            currentRound: currentRound,
            totalRounds: roundsTotal,
            isDevMode: widget.isDevTestMode,
          ),

          // DEV TEST MODE PLAYER SWITCHER TOOLBAR
          if (widget.isDevTestMode && widget.onPlayerSwitched != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.redInk, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEV TEST MODE — SWITCH ACTIVE PLAYER',
                    style: GoogleFonts.kalam(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: AppColors.redInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: widget.activePlayerId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      filled: false,
                    ),
                    items: widget.players.map((p) {
                      final data = p.data() as Map<String, dynamic>;
                      final pName = data['name']?.toString() ?? 'Player';

                      int? pCard;
                      cardSelections.forEach((k, v) {
                        if (v is Map<String, dynamic> && v['playerId'] == p.id) {
                          pCard = int.tryParse(k);
                        }
                      });

                      final String cardStatus = pCard != null ? ' (#$pCard)' : ' (No paper)';

                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(
                          '$pName$cardStatus',
                          style: GoogleFonts.patrickHand(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ballpointBlue,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        widget.onPlayerSwitched?.call(val);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Title & Status
          Text(
            'PICK A NOTEBOOK PAPER CHIT',
            style: GoogleFonts.kalam(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.ballpointBlue,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          const HandDrawnUnderline(width: 220, isDouble: false),
          const SizedBox(height: 8),

          Text(
            '$selectedCount / 6 players picked paper',
            style: GoogleFonts.caveat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: selectedCount == 6 ? AppColors.penGreen : AppColors.ballpointBlue,
            ),
          ),
          const SizedBox(height: 12),

          // Active Player Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: activePlayerCardIndex != null
                  ? AppColors.pencilGreenFill
                  : const Color(0xFFFFFDF5),
              border: Border.all(color: AppColors.ballpointBlue, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  activePlayerCardIndex != null ? Icons.check_circle : Icons.touch_app,
                  size: 18,
                  color: AppColors.ballpointBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  activePlayerCardIndex != null
                      ? '$activePlayerName: Picked Paper #$activePlayerCardIndex'
                      : '$activePlayerName: Tap a paper chit below to pick!',
                  style: GoogleFonts.kalam(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ballpointBlue,
                  ),
                ),
                if (activePlayerCardIndex != null && activePlayerHasRole) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _revealPlayerRole(widget.activePlayerId, activePlayerName),
                    child: Text(
                      '[View Role]',
                      style: GoogleFonts.caveat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.redInk,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 6 Paper Chits Grid (2 columns x 3 rows)
          AnimatedBuilder(
            animation: _shuffleController,
            builder: (context, child) {
              final double progress = _shuffleController.value;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  final int cardNum = index + 1;
                  final String cardKey = '$cardNum';
                  final selection = cardSelections[cardKey];

                  final bool isSelected = selection != null;
                  final String selectedBy = selection?['playerId']?.toString() ?? '';
                  final String selectedByName = selection?['playerName']?.toString() ?? '';
                  final bool isSelectedByActivePlayer = selectedBy == widget.activePlayerId;

                  final double scatterOffsetX = (1.0 - progress) * (math.sin(index * 2.0) * 80);
                  final double scatterOffsetY = (1.0 - progress) * (math.cos(index * 2.0) * 80);

                  return Transform.translate(
                    offset: Offset(scatterOffsetX, scatterOffsetY),
                    child: TornPaperChit(
                      isFolded: true,
                      isSelected: isSelectedByActivePlayer,
                      isTaken: isSelected,
                      takenByPlayerName: isSelectedByActivePlayer ? 'YOURS' : selectedByName,
                      angle: _paperAngles[index % _paperAngles.length],
                      onTap: _isSelecting
                          ? null
                          : () => _handlePaperTap(
                                cardNum,
                                widget.activePlayerId,
                                activePlayerName,
                              ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SecretRoleRevealDialog extends StatefulWidget {
  final String playerName;
  final String role;
  final int points;

  const _SecretRoleRevealDialog({
    required this.playerName,
    required this.role,
    required this.points,
  });

  @override
  State<_SecretRoleRevealDialog> createState() => _SecretRoleRevealDialogState();
}

class _SecretRoleRevealDialogState extends State<_SecretRoleRevealDialog> {
  bool _isFolded = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isFolded = false;
        });
      }
    });
  }

  void _foldAndClose() {
    setState(() {
      _isFolded = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF7F4EB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.ballpointBlue, width: 2),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'UNFOLDING PAPER CHIT...',
              style: GoogleFonts.kalam(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.ballpointBlue,
              ),
            ),
            const SizedBox(height: 16),

            TornPaperChit(
              label: 'YOUR ROLE',
              role: widget.role,
              points: widget.points,
              isFolded: _isFolded,
              isSelected: true,
              width: 140,
              height: 165,
              onTap: _foldAndClose,
            ),

            const SizedBox(height: 20),
            Text(
              'KEEP IT SECRET!',
              style: GoogleFonts.kalam(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.redInk,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Do not let other players see your screen.',
              textAlign: TextAlign.center,
              style: GoogleFonts.caveat(
                fontSize: 16,
                color: AppColors.pencilGrey,
              ),
            ),
            const SizedBox(height: 20),

            HandDrawnButton(
              label: 'GOT IT! KEEP SECRET',
              pencilFillColor: AppColors.pencilBlueFill,
              onPressed: _foldAndClose,
            ),
          ],
        ),
      ),
    );
  }
}
