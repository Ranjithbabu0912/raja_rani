import 'package:flutter/material.dart';

import 'game_screen.dart';

class RoleScreen extends StatelessWidget {
  final String roomId;
  final String role;
  final int points;

  const RoleScreen({
    super.key,
    required this.roomId,
    required this.role,
    required this.points,
  });

  IconData _getRoleIcon() {
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

  String _getRoleMessage() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'YOUR ROLE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 40),

                CircleAvatar(radius: 55, child: Icon(_getRoleIcon(), size: 55)),

                const SizedBox(height: 30),

                Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  '$points POINTS',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  _getRoleMessage(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),

                const SizedBox(height: 50),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(roomId: roomId),
                        ),
                      );
                    },
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
