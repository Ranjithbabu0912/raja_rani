import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../components/rr_loader.dart';
import '../services/room_service.dart';
import '../utils/app_theme.dart';
import '../widgets/kolam_painter.dart';
import '../widgets/traditional_card.dart';

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

class _CardSelectionWidgetState extends State<CardSelectionWidget> {
  final RoomService _roomService = RoomService();
  bool _isSelecting = false;

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

  String _getRoleMessage(String role) {
    switch (role.toLowerCase()) {
      case 'raja':
        return 'You are the Raja! Find the Rani.';
      case 'rani':
        return 'You are the Rani. Keep your role secret!';
      case 'manthiri':
        return 'You are the Manthiri.';
      case 'sippai':
        return 'You are the Sippai.';
      case 'police':
        return 'You are the Police.';
      case 'thirudan':
        return 'You are the Thirudan. Keep your role secret!';
      default:
        return 'Keep your role secret!';
    }
  }

  void _showRoleRevealDialog({
    required String playerName,
    required String role,
    required int points,
  }) {
    final roleColor = _getRoleColor(role);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: roleColor, width: 2),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CustomPaint(
                  painter: KolamMandalaPainter(
                    primaryColor: AppColors.terracotta,
                    secondaryColor: AppColors.turmeric,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'YOUR SECRET ROLE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 44,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: Icon(
                  _getRoleIcon(role),
                  size: 46,
                  color: roleColor,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                role.toUpperCase(),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: roleColor,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: roleColor, width: 1.2),
                ),
                child: Text(
                  '$points POINTS',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: roleColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _getRoleMessage(role),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CLOSE SECRET CARD',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCardTap(
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

    // Case 1: Card already selected by someone else
    if (selection != null) {
      final selectedBy = selection['playerId']?.toString() ?? '';
      final selectedByName =
          selection['playerName']?.toString() ?? 'Another player';

      if (selectedBy == activePlayerId) {
        // Active player tapped their own card - offer to reveal role
        _revealPlayerRole(activePlayerId, activePlayerName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This card has already been selected by $selectedByName. Please choose another card.',
            ),
            backgroundColor: AppColors.terracotta,
          ),
        );
      }
      return;
    }

    // Case 2: Active player has already picked another card
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
            'You have already selected Card $previousCardIndex. Each player can only pick one card.',
          ),
          backgroundColor: AppColors.terracotta,
        ),
      );
      return;
    }

    // Case 3: Select Card
    setState(() {
      _isSelecting = true;
    });

    try {
      await _roomService.selectRoleCard(
        roomId: widget.roomId,
        playerId: activePlayerId,
        cardIndex: cardIndex,
      );
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

    if (role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Role is assigned once card is selected.'),
          backgroundColor: AppColors.terracotta,
        ),
      );
      return;
    }

    _showRoleRevealDialog(playerName: playerName, role: role, points: points);
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
    if (activePlayerDoc == null) {
      return const RRLoader(message: 'Loading Player Data...');
    }

    final activePlayerData = activePlayerDoc.data() as Map<String, dynamic>;
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

    return Container(
      color: AppColors.warmCream,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // DEV TEST MODE PLAYER SWITCHER DROPDOWN
                if (widget.isDevTestMode && widget.onPlayerSwitched != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.turmeric.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.turmeric, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bug_report, color: AppColors.terracotta, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'DEV TEST MODE — SWITCH ACTIVE PLAYER',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: AppColors.darkBrown,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: widget.activePlayerId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            fillColor: Colors.white,
                            filled: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.borderBrown),
                            ),
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

                            return DropdownMenuItem<String>(
                              value: p.id,
                              child: Text(
                                pCard != null
                                    ? '$pName  [✓ Selected Card $pCard]'
                                    : '$pName  [❌ Pending Selection]',
                                style: TextStyle(
                                  fontWeight: p.id == widget.activePlayerId
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: pCard != null
                                      ? AppColors.leafGreen
                                      : AppColors.terracotta,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) widget.onPlayerSwitched!(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // HEADER TRADITIONAL CARD
                TraditionalCard(
                  borderColor: AppColors.terracotta,
                  borderWidth: 2,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.terracotta, width: 1.2),
                        ),
                        child: Text(
                          'ROUND $currentRound OF $roundsTotal',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '🎴 BLIND ROLE SELECTION',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkBrown,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activePlayerCardIndex != null
                            ? 'You selected Card $activePlayerCardIndex. Waiting for remaining players...'
                            : 'Pick any hidden card below to get your secret role!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // PROGRESS BAR
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: selectedCount / 6.0,
                          minHeight: 10,
                          backgroundColor: AppColors.warmCream,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            selectedCount == 6 ? AppColors.leafGreen : AppColors.terracotta,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$selectedCount / 6 Cards Selected',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: selectedCount == 6 ? AppColors.leafGreen : AppColors.terracotta,
                            ),
                          ),
                          if (selectedCount == 6)
                            const Row(
                              children: [
                                RRLoader(size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Starting round...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.leafGreen,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ACTIVE PLAYER ROLE REVEAL BUTTON CARD
                if (activePlayerCardIndex != null && activePlayerHasRole) ...[
                  TraditionalCard(
                    backgroundColor: AppColors.leafGreen,
                    borderColor: AppColors.leafGreen,
                    showKolamCorners: false,
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.style, color: AppColors.turmeric),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$activePlayerName\'s Selection',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Card $activePlayerCardIndex Picked',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.turmeric,
                            foregroundColor: AppColors.darkBrown,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _revealPlayerRole(
                            widget.activePlayerId,
                            activePlayerName,
                          ),
                          icon: const Icon(Icons.visibility),
                          label: const Text(
                            'REVEAL ROLE',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // 6 SECRET CARDS GRID (2 Rows of 3)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    final cardNum = index + 1;
                    final cardKey = '$cardNum';
                    final selection = cardSelections[cardKey];

                    final bool isSelected = selection != null;
                    final String selectedBy =
                        selection?['playerId']?.toString() ?? '';
                    final String selectedByName =
                        selection?['playerName']?.toString() ?? '';
                    final bool isSelectedByActivePlayer =
                        selectedBy == widget.activePlayerId;

                    return TraditionalCard(
                      padding: const EdgeInsets.all(8),
                      backgroundColor: isSelectedByActivePlayer
                          ? AppColors.turmeric.withValues(alpha: 0.15)
                          : isSelected
                          ? Colors.grey.shade200
                          : AppColors.cardCream,
                      borderColor: isSelectedByActivePlayer
                          ? AppColors.terracotta
                          : isSelected
                          ? Colors.grey.shade400
                          : AppColors.borderBrown,
                      borderWidth: isSelectedByActivePlayer ? 2.5 : 1.2,
                      showKolamCorners: false,
                      onTap: _isSelecting
                          ? null
                          : () => _handleCardTap(
                              cardNum,
                              widget.activePlayerId,
                              activePlayerName,
                            ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isSelectedByActivePlayer
                                ? AppColors.terracotta
                                : isSelected
                                ? Colors.grey.shade500
                                : AppColors.leafGreen,
                            child: Icon(
                              isSelectedByActivePlayer
                                  ? Icons.check
                                  : isSelected
                                  ? Icons.lock
                                  : Icons.help_outline,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'CARD $cardNum',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: isSelectedByActivePlayer
                                  ? AppColors.terracotta
                                  : AppColors.darkBrown,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSelectedByActivePlayer
                                ? 'YOUR CARD'
                                : isSelected
                                ? (selectedByName.isNotEmpty
                                      ? selectedByName
                                      : 'TAKEN')
                                : 'SECRET',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelectedByActivePlayer
                                  ? AppColors.terracotta
                                  : isSelected
                                  ? Colors.grey.shade700
                                  : AppColors.leafGreen,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
